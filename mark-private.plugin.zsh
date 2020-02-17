: '
------------------------------------------------------------------------------
         FILE:  mark-private
  DESCRIPTION:  oh-my-zsh plugin.
       AUTHOR:  marco treglia markno1.github@gmail.com
      VERSION:  1.0.0

Usage:
      mark-encode
      mark-decode
------------------------------------------------------------------------------
'

: 'Encryption'
function mark-encode() {
  receiver_pubkey=$1
  file=$2
  generate_secret $MARK_ECPR $receiver_pubkey $file.secret
  use_secret_to_encrypt $file $file.secret
  generate_hmac $file.enc $file.secret.hmac $file.secret
}


: 'Decryption'
function mark-decode() {
  sender_pubkey=$1
  filecry=$2
  generate_secret $MARK_ECPR  $sender_pubkey $filecry.secret
  generate_hmac $filecry $filecry.secret.hmac $filecry.secret
  # compare hmac
  use_secret_to_decrypt  $filecry  ${filecry/.enc/} $filecry.secret
}


: 'Encryption Local'
function mark-encode-local() {
  file=$1
  generate_secret $MARK_ECPR $MARK_ECPU $file.secret
  use_secret_to_encrypt $file $file.secret
  generate_hmac $file.enc $file.secret.hmac $file.secret
  mark-cleanup
}


: 'Decryption Local'
function mark-decode-local() {
  filecry=$1
  generate_secret $MARK_ECPR $MARK_ECPU ${filecry}.secret
  # compare hmac
  use_secret_to_decrypt  $filecry  ${filecry/.enc/} ${filecry}.secret
  mark-cleanup
}

function mark-cleanup(){
  for entry in ./*
  do
    if [[ $entry == *".secret"* ]]; then
      rm -rf $entry
    fi
  done
}



function mark-config() {
  if [ ! -d  "$HOME/$MARK_FEC" ]; then
    mkdir $HOME/$MARK_FEC
  fi
    generate_ec_private_key "$HOME/$MARK_FEC/$ECPR"
    generate_ec_public_key "$HOME/$MARK_FEC/$ECPR" "$HOME/$MARK_FEC/$ECPU"
    Mark-Load-Configuration
}


function generate_ec_private_key(){
  kpriv=$1
  openssl ecparam -genkey -param_enc explicit -out $kpriv -name brainpoolP512t1
}


function generate_secret(){
  kpriv=$1
  kpub=$2
  secret=$3
  openssl pkeyutl -derive -inkey  $kpriv -peerkey $kpub | base64 -w0 > $secret
}


function use_secret_to_encrypt(){
  file=$1
  secret=$2
  openssl enc -aes-256-cbc -in $file -out ${file}.enc -pass file:$secret
}

function generate_ec_public_key(){
  kpriv=$1
  kpub=$2
  openssl ec -in $kpriv -pubout -out $kpub
}

function generate_hash(){
  input=$1
  echo $(openssl dgst -sha256  ${input}|awk '{print $2}')
}

function generate_hmac(){
  encrypted=$1
  hmac_out=$2
  secret=$3
  openssl dgst -sha256 -hmac HMAC -macopt "hexkey:$(generate_hash $secret)"  -out $hmac_out $encrypted
}


function use_secret_to_decrypt(){
  file_enc=$1
  file=$2
  secret=$3
  openssl enc -d -aes-256-cbc -in $file_enc  -out $file -pass file:$secret
}


function Mark-Load-Configuration(){
  export ECPR=".my.ec.private"
  export ECPU=".my.ec.public"
  export MARK_FEC=".mark.private"
  if [ -d  "$HOME/$MARK_FEC" ]; then
    export MARK_ECPR="$HOME/$MARK_FEC/$ECPR"
    export MARK_ECPU="$HOME/$MARK_FEC/$ECPU"
    echo "[private-mark] $emoji[winking_face]"
  else
    echo "[private-mark]: Run $ mark-config  $emoji[dizzy_face]"
  fi
}


Mark-Load-Configuration
