#!/usr/bin/php
<?php

  // checkports.php <xml file> [ flag to show results of matching strings ] [ flag to sow SQL queries ]
  // Errors in finding ports are directed to stderr
  // status messages are directed to stdout
  
  $portsArray = array();
  $portsByCodes = false;
  $debugMatches = false;
  $errStr = "";
  $stderr = fopen('php://stderr', 'w');

  class XmlSchedules extends SimpleXMLElement {
    public function getRoutes() {
      $rts = array();
      foreach($this->schedule as $currSched) {
        $rts[] = $currSched->route;
      }
      return $rts;
    }
    
    public function getVessels() {
      $vess = array();
      foreach($this->schedule as $currSched) {
        foreach($currSched->vessel as $currVess) {
          $vess[$currVess['name']] = $currVess;
        }
      }
      return $vess;
    }
    
    public function getRouteName() {
      return $this->route;
    }
    
    public function getPortList() {
      global $portsArray;
      global $portsByCodes;
      foreach($this->vessel as $currVess) {
        foreach($currVess->port as $currPort) {
          if ((string)$currPort['code'] != '') {
            $portsByCodes = true;
            $portsArray[(string)$currPort['code']] = 1;
          } else 
            $portsArray[(string)$currPort['name']] = 1;
        }
      }
    }
  } 

  function lookupPort($str) { 
    global $portsByCodes;
    $patterns = array('/(\S)\/(\S)/');
    $replace = array("$1 / $2");
    $newstr = preg_replace($patterns, $replace, $str);
    if ($portsByCodes) return lookupPortCode($str);
    else return lookupPortByName($newstr);
  } 
 
  function lookupPortCode($code) {
    global $errStr;
    global $stderr;
    $found = true;
    $portID = 0;
    $query = "select locode.* from locode where code = '$code' order by locode.id asc";
    if (isset($_SERVER['argv'][3])) print $query."\n";
    $rs2 = mysql_query($query);
    if (!$rs2) {
      $errStr .= "DB FAILURE: $query\n".mysql_error()."\n";
      $found = false;
    } else if (mysql_num_rows($rs2) == 0) {
      // make sure locodes that are part of a altname don't trigger a false positive
      $query = "select locode.* from locode where altnames = '$code' or altnames like '%$code;%' or altnames like '%;$code%' order by locode.id asc";
      if (isset($_SERVER['argv'][3])) print $query."\n";
      $rs2 = mysql_query($query);
      if (mysql_num_rows($rs2) == 0) {
        error_log("\nERROR Port lookup error - no matches found for port code $code \n",3,"./xml-processing.log");
        $found = false;
      }
    }
    if ($found) {
      // found multiple matches?  log and return first
      if (mysql_num_rows($rs2) != 1)
        error_log("\nWARNING Port lookup error - multiple matches found for port code $code \n",3,"./xml-processing.log");
      $line = mysql_fetch_array($rs2);
      $portID = $line['id'];
      //if (trim($line['functype']) == '' || substr_compare($line['functype'],'Port',0,4) != 0)
      //  error_log("\nWARNING $code exactly matches something w/o a port designation\n",3,"./xml-processing.log");
    }
    if ($found) return $portID; else return false;
  }

  function translateAbbrv($name) {
    $retVal = $name;
    $retVal = preg_replace('/^Pt[.]* /i','Port ',$retVal);
    $retVal = preg_replace('/^St[.]* /i','Saint ',$retVal);
    $retVal = preg_replace('/ Pt[.]* /i',' Port ',$retVal);
    $retVal = preg_replace('/ St[.]* /i',' Saint ',$retVal);
    return $retVal;
  }

  // name can be <name> or <name>;<country> to help with disambiguation
 
  function lookupPortByName($name) {
    global $errStr;
    global $debugMatches, $cachedPorts;
    global $stderr;
    $tmpErr = "";
    $found = false;
    $portID = 0;
    $lastPossPort = -1;
    $minDist = 999999;
    $maxPerc = 0;
    $cntry = null;   // possible iso code of port cntry
    $cntryclause = "";
    $regionstr = "";
    $spos = strpos($name,";");
    if ($spos !== false) {
      $spos2 = strpos($name,";",$spos+1);
      if ($spos2 === false) {
        $cntry = trim(substr($name,$spos+1));
        $name = trim(substr($name,0,$spos));
        $cntryclause = " and locode.fk_country = '$cntry' ";
      } else {
        $regi = trim(substr($name,$spos+1,$spos2-$spos-1));
        $cntry = trim(substr($name,$spos2+1));
        $name = trim(substr($name,0,$spos));
        $cntryclause = " and region.region='$regi' and locode.fk_region = region.id and locode.fk_country = '$cntry' ";
	$regionstr = ", region";
      }
    }
    $name = translateAbbrv($name);

    // first lookup string in cache
    if (array_key_exists($name,$cachedPorts)) return $cachedPorts[$name];
    
    //first try to find port with functype of Port... else try again in case of locode not having a Port designation
    for ($loop=0; ($loop<2 && !$found); $loop++) {
      $funcclause = ($loop == 0) ? "locode.functype like 'Port%' and " : "";
      for($x=strlen($name)+1; ($x>1 && !$found); $x--) {
        // if country has been manually specified and port still not found, then stop looking (dont go to % searches) and fail
        if (($x < strlen($name)) && ($cntryclause != "")) { $x=1; continue; }
        $cname = ($x > strlen($name)) ? $name : substr($name,0,$x);
        $cname = addslashes($cname);
        $nameclause = ($x == strlen($name)+1) ? 
	  "(locode.name like '${cname}' or locode.altnames like '${cname}') " : 
	  "(locode.name like '${cname}%' or locode.altnames like '${cname}%' or locode.altnames like '%;${cname}%') ";
        $query = "select locode.* from locode $regionstr where $funcclause $nameclause $cntryclause order by locode.id asc";
        if (isset($_SERVER['argv'][3])) print $query."\n";
        $rs2 = mysql_query($query);
        if (!$rs2) {
          $tmpErr .= "DB FAILURE: $query\n".mysql_error()."\n";
          $x = 2;
          $loop = 3;
        } else if (mysql_num_rows($rs2) != 1) {
          if (mysql_num_rows($rs2) > 1) {
            if ($x == strlen($name)+1)
              fwrite($stderr, "WARNING:  Multiple ports found for exact match against $name\n");
            // save id of best port that matches so far
            while ($line=mysql_fetch_array($rs2)) {
              // handle names with / in them - == 2 names
              if (strpos($line['name'],'/') > 0) {
                $subn1 = substr($line['name'],0,strpos($line['name'],'/'));
                $subn2 = substr($line['name'],strpos($line['name'],'/')+1);
                $cd1 = levenshtein(strtolower($name),strtolower($subn1),2,1,5);
                $cd2 = levenshtein(strtolower($name),strtolower($subn2),2,1,5);
                $cdist = ($cd1 < $cd2) ? $cd1 : $cd2;
                similar_text(strtolower($name), strtolower($subn1), $simperc1);
                similar_text(strtolower($name), strtolower($subn2), $simperc2);
                $simperc = ($simperc1 > $simperc2) ? $simperc1 : $simperc2;
              } else {
                similar_text(strtolower($name), strtolower($line['name']), $simperc);
                $cdist = levenshtein(strtolower($name),strtolower($line['name']),2,1,5);
              }
              if ($debugMatches)
                print "$name Search On: $cname Got: {$line['name']} Lev: $cdist CurrMin: $minDist SimPer: $simperc MaxPerc: $maxPerc\n";
              if ($simperc > 75 && $simperc > $maxPerc) {
                $minDist = $cdist;
                $maxPerc = $simperc;
                $lastPossPort = $line['id'];
                $possPrintout = "Possible port found - $name {$line['code']} {$line['name']} {$line['altnames']} {$line['fk_country']}\n\n"; 
              }
              // found a (or several exact matches - take first and kill all loops)
              if ($maxPerc == 100.0) {
                $x = 2;
                $loop = 3;
                break;
              }
            }
          }
        } else {
          $found=true;
          $line = mysql_fetch_array($rs2);
          $portID = $line['id'];
          $errStr .= "Port found - $name {$line['code']} {$line['name']} {$line['altnames']} {$line['fk_country']}\n\n";
          //if ($funcclause == "")
          //  $errStr .= "WARNING: $name exactly matches something w/o a port designation\n\n";
        }
      }
    }

    if (!$found) $errStr .= $tmpErr;
    if (!$found && ($lastPossPort > -1)) {
      $found = true;
      $portID = $lastPossPort;
      $errStr .= $possPrintout;
      // flag schedule as having poss port issue
      $errStr .= "WARNING:  Possible port lookup error - multiple matches found for port $name\n\n";
    }
    if ($found) {
      $cachedPorts[$name] = $portID;
      return $portID;
    } else {
      $cachedPorts[$name] = false;
      return false;
    }
  }

  
  //////////////////////////////////////////////////////////////////////////////////////////////
  $cachedPorts = array();
  
  if (filesize($_SERVER['argv'][1]) == 0) {
    error_log("\nWARNING File ".$_SERVER['argv'][1]." is 0 bytes\n",3,"./xml-processing.log");
    exit();
  }
  $scheds = simplexml_load_file($_SERVER['argv'][1],'XmlSchedules');
  $debugMatches = isset($_SERVER['argv'][2]);

  $database = getenv('TARIDB');
  if ($database == "") $database = (strpos(getenv('PWD'),"dev") !== false) ? "tarisogadevdb" : "backend";
  $pass = "rabbitDuCKgooseMongoose"; 
  $user = "cronjob"; 

  $dbconn = mysql_connect('localhost',$user,$pass);
  if (!$dbconn || (mysql_select_db($database) === false)) {
    fwrite($stderr, "Could not connect to DB\n");
    fclose($stderr);
    exit(1);
  }
  $rs = mysql_query("SET NAMES 'utf8'");

  $errStr .= "\n***************** Port Verification: {$_SERVER['argv'][1]} ********************\n";

  $hasError = false;
  foreach($scheds->schedule as $currSched) {
    $portsArray = array();
    $sched = $currSched;
    // preprocess port list to set $portsByCode
    $sched->getPortList();

    foreach($portsArray as $key => $value) {
      if (($pID = lookupPort($key)) === false) {
        $hasError = true;
        fwrite($stderr, "ERROR: Port Lookup Failed: $key\n\n");
      }
    }
  }
  if ($hasError) fwrite($stderr, "Directory: ".getcwd()." File: ".$_SERVER['argv'][1]."\n");
  echo $errStr;
  fclose($stderr);
?>
