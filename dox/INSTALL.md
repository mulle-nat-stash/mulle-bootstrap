
## How to install

This will install **mulle-bootstrap** into `/usr/local`:

```console
./install.sh
```

Here is an example, that installs **mulle-bootstrap** into /tmp:

```console
./install.sh /tmp
```


## OS X/Linux: How to install with homebrew/linuxbrew

If you have brew you can get the latest released version with

```console
brew install mulle-kybernetik/software/mulle-bootstrap
```

### Linux/: Install with apt-get

Run with sudo:

```
sudo -s

curl -sS "https://www.mulle-kybernetik.com/dists/admin-pub.asc" | apt-key add -

echo "deb [arch=all] http://www.mulle-kybernetik.com `lsb_release -c -s` main" \
> "/etc/apt/sources.list.d/mulle-kybernetik.com-main.list"

apt-get update
apt-get -y --allow-unauthenticated install mulle-bootstrap
```

## Windows: How to install

> if you use the new [Windows 10 bash](http://www.omgubuntu.co.uk/2016/08/enable-bash-windows-10-anniversary-update), ignore this

Get [Git For Windows](https://git-scm.com/download/win).
Checkout this repository then run

```console
./install.sh ~/bin
```



