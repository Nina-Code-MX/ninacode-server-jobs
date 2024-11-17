#!/bin/bash

# Check for SSL expiration.
# soporte@ninacode.mx
# version 1.0.0

# Die Function
die () {
  printf >&2 "ERROR!\n""$@""\n\t./$0 \nExiting...\n"
  exit 1
}

logger () {
  printf >&2 $(date +"%Y%m%dT%H%M%S")"\t[sslCheck]""$@""\n"
}

awsSes () {
  logger "Sending SES"

  if [ ! -f "$aws_cnf" ]; then
    logger $aws_cnf
    die 'AWS Configuration Missing'
  fi

  source $aws_cnf

  jsonfile="$dump_path""/replicationStatus.json"
  site_rows=$@
  html_out="<h1>Inform of SSL Sites to renew</h1><br>"
  html_out="$html_out""<table border='1' cellspacing='1' cellpadding='1' style='width: 100%'>"
  html_out="$html_out""<thead><tr>"
  html_out="$html_out""<th bgcolor='#fafafa' style='background-color: #fafafa'>Site</th>"
  html_out="$html_out""<th bgcolor='#fafafa' style='background-color: #fafafa'>Issuer</th>"
  html_out="$html_out""<th bgcolor='#fafafa' style='background-color: #fafafa'>Expiration</th>"
  html_out="$html_out""</tr></thead>"
  html_out="$html_out""<tbody>$site_rows</tbody>"
  html_out="$html_out""</table><br>"
  html_out="$html_out""<p>Please resolve as soon as possible.</p>"

  txt_out="Inform of SSL Sites to renew\n"
  txt_out="$txt_out""$site_rows\n"
  txt_out="$txt_out""Please resolve as soon as possible."

  touch $jsonfile
  echo '' > $jsonfile

  echo '{' > $jsonfile
  echo -n -e "\t"'"Subject": {"Charset": "UTF-8", "Data": "[No-Reply] SSL Expiration Information"},'"\n" >> $jsonfile
  echo -n -e "\t"'"Body": {'"\n" >> $jsonfile
  echo -n -e "\t\t"'"Text": {"Charset": "UTF-8", ' >> $jsonfile
  echo '"Data": "'$txt_out'"},' >> $jsonfile
  echo -n -e "\t\t"'"Html": {"Charset": "UTF-8", ' >> $jsonfile
  echo '"Data": "'$html_out'"}' >> $jsonfile
  echo -n -e "\t"'}'"\n" >> $jsonfile
  echo '}' >> $jsonfile

  /usr/local/bin/aws ses send-email \
    --from $FROM_ADDRESS \
    --destination "ToAddresses=$TO_ADDRESS,CcAddresses=$CC_ADDRESS" \
    --message file://${jsonfile}

  logger "Cleaning local files..."

  rm -rf ${jsonfile}
}

logger "Initializing..."

# Parse Arguments
home_path="./"
aws_cnf="$home_path""/confs/.aws.cnf"
dump_path="$home_path""/dump"
next_date=$(date +'%s')
next_date=$(echo "$next_date + (7 * 24 * 60 * 60)" | bc)
ssl_renew='false'
ssl_renew_text=''

logger "Checking Sites"

while read site; do
  expiration_date=$(curl -Iv $site 2>&1 | egrep -i "expire date:" | cut -d':' -f2-)
  expiration_date=$(date -d "$expiration_date" +'%s')
  expiration_issuer=$(curl -Iv $site 2>&1 | egrep -i "issuer:" | cut -d':' -f2-)

  if [ $expiration_date -le $next_date ]; then
    logger "$site is expiring soon in <"$(date -d @${expiration_date} +'%Y-%m-%d')">, please renew the SSL."
    ssl_renew='true'
    ssl_renew_text="$ssl_renew_text<tr><td>$site</td><td>$expiration_issuer</td><td>"$(date -d @${expiration_date} +'%Y-%m-%d')"</td></tr>"
  fi
done < "$home_path""/scripts/siteList.txt"  

if [ $ssl_renew == 'true' ]; then
  awsSes $ssl_renew_text
fi

logger "Finished"

exit 0;