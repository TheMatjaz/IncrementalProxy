IncrementalProxy
================

IncrementalProxy is a database-driven external Access Control List for
Squid 3. It offers dynamic per-user restrictions of domains with temporary
unlock of domains.


Use case
--------

Usually a proxy system has some domains blocked for certain IP addresses,
subnets or simply globally. This setting is written in a text file
statically. The file has to be modified manually by the proxy admin and the
configuration of the proxy reloaded ad each change to make it effective. This
situation is really painful when a user has to access a blocked website with a
good reason for doing it (e.g. access Facebook because the Facebook page of the
company running the proxy has to be updated), especially because the proxy admin
may need a lot of time to answer the e-mail requesting the unlock.

IncrementalProxy solves this problem blocking domains on a per-user
specification (e.g. the PR department can access social media to represent the
company online, the manufacturing deparment can not) and users may activate a
temporary unlock of a blocked domain by writing a motivational paragraph for
their request on a proxy web panel. Upon request the domain is unlocked for the
specified period of time automatically. Periodically the proxy admin will check
the request list and permanently ban domains with unserious requests for that
particular user.


Domain statuses
---------------

Each domain is stored with a status for the current proxy user:

- **allowed**: the user may visit the domain;
- **limbo**: the domain is visited for the first time and the user may proceed
  to do it. This status is functionally the same as _allowed_ but offers a
  warning flag to the proxy admin to check it and set it to another status;
- **denied**: the domain is blocked but many be temporary unlocked upon
  request. After the expiration fo the unlock, returns to this status;
- **banned**: the domain is permanently blocked and can not be unlocked via
  authomatic requests.


Database views
--------------

The database setup includes editable views that may be interfaced with a Web
administration panel for the proxy admin and a Web domain-unlock-request panel
for the proxy user.


Usage
-----

1. Set up a Squid 3 proxy
1. In the configuration file set up an authentication system. Currently
   IncrmentalProxy supports Basic, as seen in section `[ 2. ]` of the
   configuration file [squid.conf](squid.conf).
1. Make the [db_blacklist_helper.py](db_blacklist_helper.py) executable.
1. In the same configuration file set the
   [db_blacklist_helper.py](db_blacklist_helper.py) to be the external ACL for
   Squid, as seen in section `[ 3. ]`.
1. Set up your RDMBS, currently IncrementalProxy supports PostgreSQL 9.0+.
1. Run the `.sql` files in the order shown by the name as an admin. The first
   generates the database the be set up and filled by the second and
   third. Alternatively load the `db_dump.sql` file.

```
psql -U db_admin -d postgres -f 01_postgresql_setup.sql
psql -U db_admin -d squid -f 02_postgresql_setup.sql
psql -U db_admin -d squid -f 01_postgresql_setup.sql
```

Proxy incrementale
==================

Modificare squid in modo che la lista di siti ammessi/proibiti sia gestita in
modo incrementale. Quando l'utente visita un sito non censito, il sistema ne
chiede la ragione, permette la visita e lo registra come "pending"; a quel
punto, l'amministratore può tramutarlo in permitted/blocked.

Problema: come gestire i contenuti inclusi da altri siti.

Lavoriamo su una macchina virtuale AWS EC2 Ubuntu 14.04.4 LTS

1. Proxy autenticato
2. Un dominio può essere in 4 stati: mai visto, autorizzato, bloccato o limbo.
3. Quando il proxy incontra un dominio "mai visto", chiede all'utente il motivo
   per cui la si visita (cioè mostra una form con un campo edit); quindi, salva
   l'opzione e lo stato diventa "limbo"
4. Quando il proxy incontra un dominio "autorizzato" o "limbo", lo lascia
   passare
5. Quando il proxy incontra un dominio "bloccato", lo blocca
6. Serve una pagina da cui l'amministratore possa vedere i domini che sono nello
   stato "limbo", e quindi spostarli in white list (autorizzato) o blacklist
   (bloccato)
