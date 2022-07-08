#!/usr/bin/with-contenv bash

CONFIG_PATH=/data/options.json

# parse inputs from options
SSH_HOST=$(jq --raw-output ".ssh_host" $CONFIG_PATH)
SSH_PORT=$(jq --raw-output ".ssh_port" $CONFIG_PATH)
SSH_USER=$(jq --raw-output ".ssh_user" $CONFIG_PATH)
SSH_KEY=$(jq --raw-output ".ssh_key[]" $CONFIG_PATH)
REMOTE_DIRECTORY=$(jq --raw-output ".remote_directory" $CONFIG_PATH)
PASSWORD=$(jq --raw-output '.password' $CONFIG_PATH)
KEEP_LOCAL_BACKUP=$(jq --raw-output '.keep_local_backup' $CONFIG_PATH)

function add-ssh-key {
    echo "Adding SSH key"
    mkdir -p /.ssh
    (
        echo "Host remote"
        echo "    IdentityFile /.ssh/id"
        echo "    HostName ${SSH_HOST}"
        echo "    User ${SSH_USER}"
        echo "    Port ${SSH_PORT}"
        echo "    StrictHostKeyChecking no"
    ) > "/.ssh/config"

    while read -r line; do
        echo "$line" >> /.ssh/id
    done <<< "$SSH_KEY"

    chmod 600 "/.ssh/config"
    chmod 600 "/.ssh/id"
}

function copy-backup-to-remote {

    cd /backup/
    echo "Copying ${slug}.tar to ${REMOTE_DIRECTORY} on ${SSH_HOST} using SCP"
    scp -F "/.ssh/config" "${slug}.tar" remote:"${REMOTE_DIRECTORY}"
}

function delete-local-backup {

    ha backups reload

    if [[ ${KEEP_LOCAL_BACKUP} == "all" ]]; then
        :
    elif [[ -z ${KEEP_LOCAL_BACKUP} ]]; then
        echo "Deleting local backup: ${slug}"
        ha backups remove ${slug}
    else

        last_date_to_keep=$($HA --raw-json backups list | jq .data.backups[].date | sort -r | \
            head -n "${KEEP_LOCAL_BACKUP}" | tail -n 1 | xargs date -D "%Y-%m-%dT%T" +%s --date )

        ha --raw-json backups list | jq -c .data.backups[] | while read backup; do
            if [[ $(echo ${backup} | jq .date | xargs date -D "%Y-%m-%dT%T" +%s --date ) -lt ${last_date_to_keep} ]]; then
                echo "Deleting local backup: $(echo ${backup} | jq -r .slug)"
                ha backups remove $(echo ${backup} | jq -r .slug)
            fi
        done

    fi
    echo Exiting
}

function create-local-backup {
    name="Automated backup $(date +'%Y-%m-%d %H:%M')"
    echo "Creating local backup: \"${name}\""
	if [[ -z $PASSWORD ]]; then
      slug=$(ha backups new --name="${name}" | cut -d' ' -f2)
	else
      slug=$(ha backups new --name="${name}" --password="${PASSWORD}" | cut -d' ' -f2)
	fi
    echo "Backup created: ${slug}"
}

add-ssh-key
create-local-backup
copy-backup-to-remote
delete-local-backup

echo "Backup process done!"
exit 0
