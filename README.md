sympl
========================================================================

Configure an installation of Sympl (https://sympl.host/)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with sympl](#setup)
    * [What sympl affects](#what-sympl-affects)
    * [Beginning with sympl](#beginning-with-sympl)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

Description
------------------------------------------------------------------------

From [What is Sympl?](https://sympl.host/what-is-sympl/):

> _Sympl_ (pronounced ‘Simple’) is a collection of open-source scripts
> and templates which allow you to automatically and efficiently
> configure your website and email on a virtual or dedicated Linux
> server hosting running Debian.

This Puppet module can configure an installation of Sympl and manage the
domains hosted by the server.

Setup
------------------------------------------------------------------------

### What sympl affects

Almost anything configured by Sympl can be managed from this module. In
particular:

- Directories under `/srv`
- System configuration of Sympl in `/etc`
- System configuration for the hosted domains in `/etc`

### Beginning with sympl

To have Puppet install Sympl with the default parameters, declare the
`sympl` class:

```pp
include sympl
```

When declared with the default options, Puppet:

- Installs the Sympl repo and packages
- Configures the default host-specific domain
- Starts the Sympl services

Usage
------------------------------------------------------------------------

### Configuring domains

Make sure you've declared the `sympl` base class before trying to use
Sympl's defined types.

To configure a Sympl-hosted domain, the only required parameter is the
name of a `sympl::domain` defined type:

```pp
sympl::domain { 'example.com': }
```

Since Sympl automatically serves both the bare form of the domain and
the form `www.example.com`, this is the only additional resource needed
to get your web site up and running.

To configure aliases of the domain and serve the same content, set the
`domain_aliases` parameter:

```pp
sympl::domain { 'example.com':
  domain_aliases  => [
    'my-brilliant-site.com',
  ],
}
```

To set up the alias so that it redirects to the original web site, put
something like this in `/srv/example.com/public/htdocs/.htaccess`:

```
RewriteEngine on
RewriteCond %{HTTP_HOST} !www.example.com$ [NC]
RewriteRule ^(.*)$ http://www.example.com/$1 [R=301,L]
```

(This is considered to be part of the web site's content, so the Sympl
module doesn't try to configure `.htaccess` files.)

### Configuring domains with SSL

Sympl domains will automatically try to obtain a certificate from
[Let's Encrypt](https://letsencrypt.org/); you can make this explicit by
setting the `ssl_provider` parameter:

```pp
sympl::domain { 'example.com':
  ssl_provider => 'letsencrypt',
}
```

Sympl also supports automatically generating self-signed certificates
with `ssl_provider => 'selfsigned'` or you can make your own certificate
signing request and install these with files in the domain. To turn off
automatic generation of certificates, set the SSH provider to `false`.

See the [Sympl documentation](https://wiki.sympl.host/view/Sympl) for
other possibilities.

### Configuring domains via Hiera

You can also use automatic parameter lookup to configure Sympl domains,
using the following structures:

```yaml
---
sympl::domains:
  example.com:
    crontab:
      mailto: webmaster@example.com
    dns:
      ttl: 86400
    domain_aliases:
      - my-brilliant-site.com
    mail:
      antispam: tag
      blacklist: zen
      mail_aliases:
        abuse: postmaster@example.com
    ssl:
      provider: false
    web:
      stats: true
```

Limitations
------------------------------------------------------------------------

This module doesn't attempt to configure FTP for a domain.

Development
------------------------------------------------------------------------

Please do contribute to the development of this module at
[GitHub](https://github.com/iainhallam/puppet-sympl).
