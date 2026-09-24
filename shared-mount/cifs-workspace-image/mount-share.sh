#!/usr/bin/env bash

USER_PWD="hello"
USER_PWD_CHK="goodbye"
echo "Enter the URL for the CIFS share:"
read CIFS_URL
echo "Enter the mountpoint for the CIFS share:"
read CIFS_MNT
echo "Enter the user id for the CIFS mount:"
read CIFS_USER
while [[ ${USER_PWD} != ${USER_PWD_CHK} ]]
do
  echo "Enter the password for the CIFS mount:"
  read -s USER_PWD
  echo "Re-Enter the password for the CIFS mount:"
  read -s USER_PWD_CHK
  if [[ ${USER_PWD} != ${USER_PWD_CHK} ]]
  then
    echo "Passwords do not match. Try Again."
  fi
done

if [[ ! -d ${CIFS_MNT} ]]
then
  mkdir -p ${CIFS_MNT}
fi
mount -t cifs -o username=${CIFS_USER},password=${USER_PWD},uid=$(id -u),gid=$(id -g) ${CIFS_URL} ${CIFS_MNT}
