#!/usr/bin/perl -w

use strict;


use Time::localtime;

$::numValidCharList = 85;
$::dummyString = "{{{{";

#
#FOR TEST
#
my $password = $ARGV[0];
my $scrambled_string = scrambleString($password);
print $scrambled_string;


sub getvalidCharList
{
  my $pos = shift;
  my @validCharList =
  (
    "!",  "#", "\$",  "%",  "&",  "(", ")",  "*",  "+",  "-",
    ".",  "0",   "1",  "2",   "3",  "4",  "5",  "6", "7", "8",
    "9", ":",  ";",  "<",  ">",  "?",  "@",  "A",  "B", "C",
    "D",  "E",  "F",  "G",  "H",  "I",  "J",  "K",  "L", "M",
    "N", "O",  "P",  "Q",  "R",  "S",  "T", "U", "V", "W",
    "X",  "Y",  "Z",  "[", "]",  "_",  "a",  "b",  "c",  "d",
    "e",  "f",  "g",  "h",  "i",  "j",  "k",  "l",  "m",  "n",
    "o",  "p",  "q",  "r",  "s",  "t",  "u",  "v",  "w",  "x",
    "y",  "z",  "{",  "|",  "}"
  );
  return $validCharList[$pos];
}

sub encodePassword
{
  my $p = shift;
  my $sPass = ":";
  my $sTmp = "";


  if (!$p)
  {
    return "";
  }
  for (my $i = 0; $i < length($p); $i++)
  {
    my $c = substr($p,$i,1);
    my $a=ord($c);

    $sTmp=($a+$i+1).":";
    $sPass .=$sTmp;
    $sTmp = "";
  }

  return $sPass;
}

sub findCharInList
{
  my $c = shift;
  my $i = -1;

  for (my $j = 0; $j < $::numValidCharList; $j++)
  {
    my $randchar = getvalidCharList($j);
    if ($randchar eq $c)
    {
      $i = $j;
      return $i;
    }
  }


  return $i;
}


sub getRandomValidCharFromList
{
  my $tm = localtime;
  my $k = ($tm->sec);

  return getvalidCharList($k);
}


sub scrambleString
{
  my $s = shift;
  my $sRet = "";
  
  if (!$s)
  {
    return $s;
  }
  my $str = encodePassword($s);
  if (length($str) < 32)
  {
    $sRet .= $::dummyString;
  }

  for ( my $iR = (length($str) - 1); $iR >= 0; $iR--)
  {
    #
    #Reverse string.
    #
    $sRet .= substr($str,$iR,1);
  }

  if (length($sRet) < 32)
  {
    $sRet .= $::dummyString;
  }

  my $app=getRandomValidCharFromList();
  my $k=ord($app);
  my $l=$k + length($sRet) -2;
  $sRet= $app.$sRet;

  for (my $i1 = 1; $i1 < length($sRet); $i1++)
  {

    my $app2=substr($sRet,$i1,1);
    my $j = findCharInList($app2);
    if ($j == -1)
    {
      return $sRet;
    }
    my $i = ($j + $l * ($i1 + 1)) % $::numValidCharList;
    my $car=getvalidCharList($i);

    $sRet=substr_replace($sRet,$car,$i1,1);

  }

  my $c = (ord(getRandomValidCharFromList())) + 2;
  my $c2=chr($c);

  $sRet=$sRet.$c2;

#  return URLEncode($sRet);
   return $sRet;
}

sub URLEncode 
{
  my $theURL = $_[0];
  $theURL =~ s/&/&amp;/g;
  $theURL =~ s/\"\"/&quot;/g;
  $theURL =~ s/\'/&#039;/g;
  $theURL =~ s/</&lt;/g;
  $theURL =~ s/>/&gt;/g;
  return $theURL;
}

sub substr_replace
{
  my $str = shift;
  my $ch = shift;
  my $pos = shift;
  my $qt = shift;
  
  my @list = split (//,$str);
  my $count = 0;
  my $tmp_str = '';
  foreach my $key(@list)
  {
    if ($count != $pos)
    {
      $tmp_str .= $key;
    }
    else
    {
      $tmp_str .= $ch;
    }
    $count++;
  }
  return $tmp_str;
}
