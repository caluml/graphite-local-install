#!/bin/bash

# I don't like letting Python install stuff all over my system without some sort of package management.
# Graphite has lots of dependencies, so I want to keep them all in one place.
# I want to be able to install graphite as a non-root user, in a specific location.

# For CentOS 6.6
# Taken from https://gist.github.com/SpOOnman/5957589

# requirements:
# gcc, xz

export INSTALLLOC=/opt/graphite

export PYTHONVER=2.6.6 # Update PYVER if you change this.
export PYVER=2.6

export CFLAGS="-I$INSTALLLOC/include -I$INSTALLLOC/include/python$PYVER"
export CPPFLAGS="-I$INSTALLLOC/include  -I$INSTALLLOC/include/python$PYVER"
export PKG_CONFIG_PATH="$INSTALLLOC/lib/pkgconfig"
export LDFLAGS="-L$INSTALLLOC/lib -L$INSTALLLOC/lib/python$PYVER"
export LD_LIBRARY_PATH="$INSTALLLOC/lib:$INSTALLLOC/lib/python$PYVER:$INSTALLLOC/lib/python$PYVER/site-packages/cairo"
export PYTHONPATH="$INSTALLLOC/lib/python:$INSTALLLOC/lib/python$PYVER/site-packages:$INSTALLLOC/.local/bin/usr/local/lib/python$PYVER/site-packages"
export PATH="$INSTALLLOC/.local/bin:$PATH"

# ---- 2. Libraries ----
# These libraries are required by Graphite. You need to compile them, because other libraries and python modules
# need their headers. They are installed to $INSTALLLOC/lib and headers are placed in $INSTALLLOC/include.

wget http://zlib.net/zlib-1.2.8.tar.gz
wget ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/libpng-1.6.17.tar.gz
wget http://www.sqlite.org/2013/sqlite-autoconf-3071700.tar.gz

tar zxf zlib-1.2.8.tar.gz
tar zxf libpng-1.6.17.tar.gz
tar zxf sqlite-autoconf-3071700.tar.gz

(cd zlib-1.2.8 && ./configure --prefix=$INSTALLLOC && make && make install ) || echo ERROR BUILDING zlib
(cd libpng-1.6.17 && ./configure --prefix=$INSTALLLOC && make && make install ) || echo ERROR BUILDING libpng
(cd sqlite-autoconf-3071700 && ./configure --prefix=$INSTALLLOC && make && make install ) || echo ERROR BUILDING sqlite

# ---- 3. Python
# Python installed by default in CentOS may miss some native modules compiled. You need to recompile.

wget http://www.python.org/ftp/python/$PYTHONVER/Python-$PYTHONVER.tgz

tar zxf Python-$PYTHONVER.tgz
cd Python-$PYTHONVER

# enable-shared is crucial here
./configure --enable-shared --prefix=$INSTALLLOC
make

# Check output for this line:
# Python build finished, but the necessary bits to build these modules were not found:
# Make sure that _zlib and _sqlite3 IS NOT on that list. Otherwise you miss dependencies or you had errors before.

make install

# Now you can have two Python installations in system. I use $INSTALLLOC/bin/python everywhere from now on to use my version.

# ---- 4. Cairo ----
# Cairo has some dependencies to fulfill.

cd -
wget http://cairographics.org/releases/pixman-0.26.2.tar.gz
wget ftp://sourceware.org/pub/libffi/libffi-3.0.11.tar.gz
wget http://ftp.gnome.org/pub/GNOME/sources/glib/2.31/glib-2.31.22.tar.xz
wget http://cairographics.org/releases/cairo-1.12.2.tar.xz
wget http://cairographics.org/releases/py2cairo-1.10.0.tar.bz2

tar xzf pixman-0.26.2.tar.gz
tar xzf libffi-3.0.11.tar.gz
unxz glib-2.31.22.tar.xz
unxz cairo-1.12.2.tar.xz
tar xf glib-2.31.22.tar
tar xf cairo-1.12.2.tar
tar xjf py2cairo-1.10.0.tar.bz2

(cd libffi-3.0.11 && ./configure --prefix=$INSTALLLOC && make && make install ) || echo ERROR BUILDING libffi
(cd glib-2.31.22 && ./configure --prefix=$INSTALLLOC && make && make install ) || echo ERROR BUILDING glib
(cd pixman-0.26.2 && ./configure --prefix=$INSTALLLOC && make && make install ) || echo ERROR BUILDING pixman
(cd cairo-1.12.2 && ./configure --prefix=$INSTALLLOC && make && make install ) || echo ERROR BUILDING cairo
(cd py2cairo-1.10.0 && $INSTALLLOC/bin/python ./waf configure --prefix=$INSTALLLOC && $INSTALLLOC/bin/python ./waf build && $INSTALLLOC/bin/python ./waf install ) || echo ERROR BUILDING pycairo

# Check if cairo is properly installed:
$INSTALLLOC/bin/python -c 'import cairo; print cairo.version' || echo ERROR RUNNING cairo
# You should see cairo version number.
# If there is an import error, there is something wrong with your PYTHONPATH.

# ---- 5. Django and modules ----
# Remember that it is all installed in user directory.

wget https://django-tagging.googlecode.com/files/django-tagging-0.3.1.tar.gz
wget https://www.djangoproject.com/m/releases/1.5/Django-1.5.1.tar.gz
wget https://pypi.python.org/packages/source/z/zope.interface/zope.interface-4.0.5.zip#md5=caf26025ae1b02da124a58340e423dfe
wget http://twistedmatrix.com/Releases/Twisted/11.1/Twisted-11.1.0.tar.bz2

unzip zope.interface-4.0.5.zip
tar zxf django-tagging-0.3.1.tar.gz
tar zxf Django-1.5.1.tar.gz
tar jxf Twisted-11.1.0.tar.bz2

(cd zope.interface-4.0.5 && $INSTALLLOC/bin/python setup.py install --user ) || echo ERROR BUILDING zope.interface
(cd Django-1.5.1 && $INSTALLLOC/bin/python setup.py install --user ) || echo ERROR BUILDING Django
(cd django-tagging-0.3.1 && $INSTALLLOC/bin/python setup.py install --user ) || echo ERROR BUILDING django-tagging
(cd Twisted-11.1.0 && $INSTALLLOC/bin/python setup.py install --user ) || echo ERROR BUILDING Twisted

# ---- 6. Graphite ----
# Remember that it is all installed into $INSTALLLOC/graphite directory!

wget https://launchpad.net/graphite/0.9/0.9.10/+download/graphite-web-0.9.10.tar.gz
wget https://launchpad.net/graphite/0.9/0.9.10/+download/carbon-0.9.10.tar.gz
wget https://launchpad.net/graphite/0.9/0.9.10/+download/whisper-0.9.10.tar.gz
tar zxf graphite-web-0.9.10.tar.gz
tar zxf carbon-0.9.10.tar.gz
tar zxf whisper-0.9.10.tar.gz

(cd whisper-0.9.10 && $INSTALLLOC/bin/python setup.py install --home=$INSTALLLOC ) || echo ERROR BUILDING whisper
(cd carbon-0.9.10 && $INSTALLLOC/bin/python setup.py install ) || echo ERROR BUILDING carbon

cd graphite-web-0.9.10

# You're almost there. Check if all dependencies are met:
$INSTALLLOC/bin/python check-dependencies.py

# There should be no fatal errors, only warnings for optional modules.
$INSTALLLOC/bin/python setup.py install

# ---- 7. Configuration ----

cd $INSTALLLOC/conf

# Copy example configurations
cp carbon.conf.example carbon.conf
cp storage-schemas.conf.example storage-schemas.conf
vim storage-schemas.conf
# You should really read document on how to configure your storage. It is a quick read:
# http://graphite.wikidot.com/getting-your-data-into-graphite
# Configure it the way you need.

cd $INSTALLLOC/webapp/graphite
cp local_settings.py.example local_settings.py

vim local_settings.py
# This file is crucial:
# Line around 13: setup your TIME_ZONE from this list: http://stackoverflow.com/questions/13866926/python-pytz-list-of-timezones
# Line around 23: DEBUG = True
# Line around 24: append ALLOWED_HOSTS = ["*"]
# Lines around 46-54: change paths from /opt/graphite to your explicit graphite installation dir,
# for example /home/you/graphite. $INSTALLLOC doesn't work here!
# Uncomment lines 141-150 (starting with DATABASES) and update NAME with full explicit database path. $INSTALLLOC doesn't work here!

vim app_settings.py
# Set SECRET_KEY

# Create new database for Graphite web application
$INSTALLLOC/bin/python manage.py syncdb

# Start carbon deamon
$INSTALLLOC/bin/python $INSTALLLOC/bin/carbon-cache.py status
$INSTALLLOC/bin/python $INSTALLLOC/bin/carbon-cache.py start

# I run development graphite server in a screen, since I cannot expose it via httpd.
screen

# In screen
$INSTALLLOC/bin/python $INSTALLLOC/webapp/graphite/manage.py runserver 0.0.0.0:8080

# Detach with Control-A, Control-D (attach again with screen -r next time)

# Check if it works, you should see <title>Graphite Browser</title>
curl localhost:8000

# You can run some example client to send some stats.
# You can adjust example-client.py delay value for more/less stats.
cd $INSTALLLOC/graphite/examples
$INSTALLLOC/bin/python example-client.py

# Done!
# Easy as pie :)
