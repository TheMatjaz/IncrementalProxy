## Update system
apt-get update
apt-get upgrade

## Install matjaz's dotfiles
bash -c "$(wget https://raw.github.com/TheMatjaz/dotfiles/debian-ubuntu/matjaz_dotfiles_installer.sh -O -)"
and run the '0' in it

## Database
sudo apt-get install postgresql
run postgresql setup files 01-... 02-... 03-...

## Git repo
mkcd ~/Development/IncrementalProxy.git
git init --bare
(on the laptop: git remote add )
git clone locally bare repository to ~/Development/IncrementalProxy

## Squid
install squid 3.5
sudo rm /etc/squid3/squid.conf; sudo ln -s /home/mat/Development/IncrementalProxy /etc/squid3/squid.conf
Change configuration file to work with correct usernames and paths to helpers
sudo apt-get install python3-psycopg2 libdbd-pg-perl (libpq-dev)

sudo -s
su - postgres
psql
create role mat with superuser password 'mypassword' with login;
exit
psql -U mat -d postgres

sudo chown proxy:proxy /var/log/squid /var/spool/squid3
change line in pg_hba.conf: 
   local   all             all                                     peer
to
   local   all             all                                     md5


# Test redirection with wget
wget --delete-after -e use_proxy=yes -e http_proxy=localhost:18080 --proxy-user=gustin --proxy-password=pwgustin minecraft.matjaz.it

# Apache, PHP
sudo apt-get install apache2 php php-pgsql 
sudo phpenmod pgsql
