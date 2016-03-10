Proxy incrementale
==================

Modificare squid in modo che la lista di siti ammessi/proibiti sia gestita in modo incrementale. Quando l'utente visita un sito non censito, il sistema ne chiede la ragione, permette la visita e lo registra come "pending"; a quel punto, l'amministratore può tramutarlo in permitted/blocked.

Problema: come gestire i contenuti inclusi da altri siti.

Lavoriamo su una macchina virtuale AWS EC2 Ubuntu 14.04.4 LTS

1. Proxy autenticato
2. Un dominio può essere in 4 stati: mai visto, autorizzato, bloccato o limbo.
3. Quando il proxy incontra un dominio "mai visto", chiede all'utente il motivo per cui la si visita (cioè mostra una form con un campo edit); quindi, salva l'opzione e lo stato diventa "limbo"
4. Quando il proxy incontra un dominio "autorizzato" o "limbo", lo lascia passare
5. Quando il proxy incontra un dominio "bloccato", lo blocca
6. Serve una pagina da cui l'amministratore possa vedere i domini che sono nello stato "limbo", e quindi spostarli in white list (autorizzato) o blacklist (bloccato)
