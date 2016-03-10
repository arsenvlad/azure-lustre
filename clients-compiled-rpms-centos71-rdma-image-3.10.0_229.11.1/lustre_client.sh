#!/bin/bash

# ./lustre_client.sh -n CLIENTCENTOS7.1 -i 0 -d 0 -m 10.1.0.4 -l 10.1.0.7 -f scratch

log()
{
	echo "$1"
	logger "$1"
}

# Initialize local variables
# Get today's date into YYYYMMDD format
NOW=$(date +"%Y%m%d")
FILESYSTEMSTRIPECOUNT=-1

# Get command line parameters
while getopts "n:i:d:m:l:f:" opt; do
	log "Option $opt set with value ${OPTARG})"
	case "$opt" in
	n)	NODETYPE=$OPTARG
		;;
	i)	NODEINDEX=$OPTARG
		;;
	d)	NODETYPEDISKCOUNT=$OPTARG
		;;
	m)	MGSIP=$OPTARG
		;;
	l)	LOCALIP=$OPTARG
		;;
	f)	FILESYSTEMNAME=$OPTARG
		;;
	esac
done

fatal() {
    msg=${1:-"Unknown Error"}
    log "FATAL ERROR: $msg"
    exit 1
}

# Retries a command on failure.
# $1 - the max number of attempts
# $2... - the command to run
retry() {
    local -r -i max_attempts="$1"; shift
    local -r cmd="$@"
    local -i attempt_num=1
 
    until $cmd
    do
        if (( attempt_num == max_attempts ))
        then
            log "Command $cmd attempt $attempt_num failed and there are no more attempts left!"
			return 1
        else
            log "Command $cmd attempt $attempt_num failed. Trying again in 5 + $attempt_num seconds..."
            sleep $(( 5 + attempt_num++ ))
        fi
    done
}

# You must be root to run this script
if [ "${UID}" -ne 0 ]; then
    fatal "You must be root to run this script."
fi

if [[ -z ${NODETYPE} ]]; then
    fatal "No node type specified, can't proceed."
fi

if [[ -z ${NODEINDEX} ]]; then
    fatal "No node index specified, can't proceed."
fi

if [[ -z ${NODETYPEDISKCOUNT} ]]; then
    fatal "No node type disk count specified, can't proceed."
fi

if [[ -z ${MGSIP} ]]; then
    fatal "No MGS IP specified, can't proceed."
fi

if [[ -z ${LOCALIP} ]]; then
    fatal "No local IP specified, can't proceed."
fi

if [[ -z ${FILESYSTEMNAME} ]]; then
    fatal "No filesystem name specified, can't proceed."
fi

log "NOW=$NOW NODETYPE=$NODETYPE NODEINDEX=$NODEINDEX MGSIP=$MGSIP LOCALIP=$LOCALIP FILESYSTEMNAME=$FILESYSTEMNAME"

add_to_fstab() {
	device="${1}"
	mount_point="${2}"
	if grep -q "$device" /etc/fstab
	then
		log "Not adding $device to /etc/fstab (it's  already there)"
	else
		line="$device $mount_point lustre defaults,_netdev 0 0"
		log $LINE
		echo -e "${line}" >> /etc/fstab
	fi
}

install_lustre_centos71()
{
	# Install wget and dstat
	yum install -y wget dstat
	
	# Download pre-compiled RPMS
	wget --tries 10 --waitretry 15 https://raw.githubusercontent.com/arsenvlad/azure-lustre/master/clients-compiled-rpms-centos71-rdma-image-3.10.0_229.11.1/rmps/lustre-client-2.7.0-3.10.0.x86_64.rpm
	wget --tries 10 --waitretry 15 https://raw.githubusercontent.com/arsenvlad/azure-lustre/master/clients-compiled-rpms-centos71-rdma-image-3.10.0_229.11.1/rmps/lustre-client-modules-2.7.0-3.10.0.x86_64.rpm
	
	# Install Lustre RPMs
	yum --nogpgcheck localinstall -y lustre-client-2.7.0-3.10.0.x86_64.rpm lustre-client-modules-2.7.0-3.10.0.x86_64.rpm

	modprobe lustre
	
	# To prevent the current kernel from being updated, add the following exclude line to [base] and [updates] in CentOS-Base.repo
	exclude="exclude = kernel kernel-headers kernel-devel kernel-debug-devel"
	sed "/\[base\]/a ${exclude}" -i /etc/yum.repos.d/CentOS-Base.repo
	sed "/\[updates\]/a ${exclude}" -i /etc/yum.repos.d/CentOS-Base.repo
	sed "/\[openlogic\]/a ${exclude}" -i /etc/yum.repos.d/OpenLogic.repo
}

create_client() {
	log "Create Lustre CLIENT"
	
	device=$MGSIP@tcp:/$FILESYSTEMNAME
	log "DEVICE $device"
	
	mount_point=/mnt/$FILESYSTEMNAME
	log "MOUNT_POINT $mount_point"
	
	mkdir -p $mount_point
	add_to_fstab $device $mount_point
	retry 5 mount -a
	
	# Create test file
	dd if=/dev/zero of=$mount_point/test_$(hostname).dat bs=1M count=200
	
	cd $mount_point
	ls -lsah
	
	# Display stripe configuration
	lfs getstripe $mount_point
	
	# Display free space
	lfs df -h
}

if [ "$NODETYPE" == "CLIENTCENTOS7.1" ]; then
	install_lustre_centos71
	create_client
fi