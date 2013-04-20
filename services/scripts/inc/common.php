<?php

function error($error_msg)
{
  echo $error_msg;
  exit;
}

function check_args($args)
{
  $data = file_get_contents("php://input");
  if ($data != '' && json_decode($data))
  {
    $params = json_decode($data, true); 
  }
  else
    $params = $_POST;
  $params = array_merge($params, $_COOKIE);
  $result = array();
  foreach ($args as $arg)
  {
    if (isset($params[$arg]))
      $result[$arg] = $params[$arg];
  }
  return $result;
}

function required_args($args)
{
  $a = check_args($args);
  foreach ($args as $arg)
    if (! array_key_exists($arg, $a))
      error('Parameter '.$arg.' isn\'t defined');
}

?>