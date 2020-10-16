#!/data/data/com.termux/files/usr/bin/bash
folder=opensuse-leap-fs
if [ -d "$folder" ]; then
	first=1
	echo "skipping downloading"
fi
tarball="opensuse-leap-rootfs.tar.xz"
if [ "$first" != 1 ];then
	if [ ! -f $tarball ]; then
		echo "Downloading Rootfs, this may take a while depending on your internet speed."
		case `dpkg --print-architecture` in
		aarch64)
			archurl="arm64" ;;
		arm)
			archurl="armhf" ;;	
		amd64)
			archurl="amd64" ;;
		x86_64)
			archurl="amd64" ;;	
		*)
			echo "unknown architecture"; exit 1 ;;
		esac
		wget "http://download.opensuse.org/ports/aarch64/distribution/leap/15.2/appliances/openSUSE-Leap-15.2-ARM-XFCE.aarch64-rootfs.aarch64.tar.xz" -O $tarball
	fi
	cur=`pwd`
	mkdir -p "$folder"
	mkdir -p "$folder/links"
	cd "$folder"
	echo "Extracting Rootfs, please be patient."
	proot --link2symlink tar -xJf ${cur}/${tarball} --exclude='dev'||:
	
	echo "Setting up name server"
	echo "127.0.0.1 localhost" > etc/hosts
    echo "nameserver 8.8.8.8" > etc/resolv.conf
    echo "nameserver 8.8.4.4" >> etc/resolv.conf
    echo "Patching Yast"
    sed -i '59,59 s/^/#/' usr/sbin/yast2
    sed -i '66,69 s/^/#/' usr/sbin/yast2
	cd "$cur"
fi
mkdir -p opensuse-leap-binds
bin=start-leap.sh
echo "writing launch script"
cat > $bin <<- EOM
#!/bin/bash
clear
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
## zypper patch
export PROOT_L2S_DIR=`pwd`/opensuse-leap-fs/links
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A opensuse-leap-binds)" ]; then
    for f in opensuse-leap-binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b opensuse-leap-fs/root:/dev/shm"
## uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to / 
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

echo "fixing shebang of $bin"
termux-fix-shebang $bin
echo "making $bin executable"
chmod +x $bin
echo "removing image for some space"
rm $tarball
echo "You can now launch openSUSE Leap with the ./${bin} script"
wget -q https://raw.githubusercontent.com/radumamy/Termux-openSUSE/master/Scripts/Installer/openSUSE/setup -O $folder/root/setup
clear
echo "Starting Setup"
echo "bash ~/setup
switch-user; exit" > $folder/root/.bash_profile
echo " "
bash $bin 
