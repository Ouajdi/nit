Benitlux manages a mailing list to keep faithful bargoers informed of the current beer offer at the excellent Brasserie Bénélux http://brasseriebenelux.com/.

This project is composed of two programs:

* a Web interface to subscribe and unsubscribe,
* and a daily background program which updates the BD and send emails.

# Compile and execute

Make sure all the required packages are installed with: `apt-get install libevent-dev libsqlite3-dev libcurl4-gnutls-dev sendmail`

To compile, run: `make`

To launch the daily background program, run: `bin/benitlux_daily` (the argument `-e` activates sending emails)

To launch the Web interface, run: `bin/benitlux_web`

The Web interface will be accessible at http://localhost:8080/

# Main server

The Benitlux application is deployed with other `nitcorn` projects at http://benitlux.xymus.net/
