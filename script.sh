#/bin/sh/
echo "Votre email en minuscule svp:"
read input1
EMAIL="$input1"
EMAILLOWER="$input1"
echo "Votre mot de passe svp:"
read input2
PASSWORD="$input2"

echo "Numéro de la session svp:"
read input3

ENCODEDPW=$(echo -n $PASSWORD$EMAILLOWER | openssl dgst -binary -sha256 | openssl base64)

BODY="{\"email\": \"$EMAIL\", \"password\": \"$ENCODEDPW\"}" 

#on efface le fichier de cookie pour partir à neuf dans le cas que nous l'avions déjà utiliser
\rm cookie-jar.txt

#On s'authentifie et on garde le cookie dans le fichier
/usr/bin/curl -c cookie-jar.txt -X POST -H 'Content-Type: application/json' --data "$BODY" https://members-ng.iracing.com/auth

#si on veut voir la qualif, il faut mettre -1 à simsession_number au lieu de 0 qui est la race
#ceci nous donne un lien web avec le nombre de chunk de donner. pour indi 1h nous avions 3chunk, peut etre un 4 pourrait être nécessaire si on fait plus de tours et nous sommes plus nombreux.
lapdata=$(/usr/bin/curl -s -b cookie-jar.txt -X GET -H 'Content-Type: application/json' "https://members-ng.iracing.com/data/results/lap_chart_data?subsession_id=$input3&simsession_number=0" | jq -r .link)

if [ -z $lapdata ] ; then 
  #on construit les urls de chacun des chunks
  chunk0=$(curl -s $lapdata | jq -r '.chunk_info.base_download_url + "" + .chunk_info.chunk_file_names.[0]')
  chunk1=$(curl -s $lapdata | jq -r '.chunk_info.base_download_url + "" + .chunk_info.chunk_file_names.[1]')
  chunk2=$(curl -s $lapdata | jq -r '.chunk_info.base_download_url + "" + .chunk_info.chunk_file_names.[2]')

  #pour chaucun des chunks on va checker les laps avec contacts par pilote et on affiche le numéro de lap
  curl -s $chunk0  | jq '.[] | select ( .lap_events | contains(["contact"])) | .name + ":" + (.lap_number|tostring)'
  curl -s $chunk1  | jq '.[] | select ( .lap_events | contains(["contact"])) | .name + ":" + (.lap_number|tostring)'
  curl -s $chunk2  | jq '.[] | select ( .lap_events | contains(["contact"])) | .name + ":" + (.lap_number|tostring)'
else
  echo probleme 
fi 
