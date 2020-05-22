# who-at-home
<p>
Script which allows you to check if specified host is alive and send information about it to server.

For example it can be used to check which householder is at home or outside the home (and how long) just by specifying his or her cellphone's IP.
It's designed to be run on your LAN's server and to upload information to external server.

<ul>
<li>Logging via keys is necessary.</li>
<li>Script should be run from cron, e.g. every 1 minute. It runs constantly, can't be run in multiple instances.</li>
<li>Script may have to be run by root (e.g. when only root can use sockets - necessary for "ping" command).</li>
</ul>
</p>
