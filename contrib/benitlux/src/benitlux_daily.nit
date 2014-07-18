# This file is part of NIT (http://www.nitlanguage.org).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Daily program to fetch and parse the Web site, update the database and email subscribers
module benitlux_daily

import curl
import sendmail
import opts

import benitlux_model

redef class Text
	# Return a `String` without any HTML tags (such as `<br />`) from `recv`
	fun strip_tags: String
	do
		var str = to_s
		var new_str = ""

		var from = 0
		loop
			var at = str.index_of_from('<', from)
			if at == -1 then break

			new_str += str.substring(from, at-from)

			at = str.index_of_from('>', at)
			assert at != -1

			from = at+1
		end

		return new_str
	end

	# Return an `Array` of the non-empty lines composing `recv`
	fun to_clean_lines: Array[String]
	do
		var orig_lines = split_with("\n")
		var new_lines = new Array[String]

		for line in orig_lines do
			line = line.trim

			# remove empty lines
			if line == "&nbsp;" then continue
			if line.is_empty then continue

			new_lines.add line.to_s
		end

		return new_lines
	end
end

# Main program logic
class Benitlux
	# The street on which is the Benelux
	var street: String

	# The url of this precive Benelux
	var url: String

	# Path to the database
	var db_path: String

	# Beers that are available today
	var beers = new HashSet[Beer]

	# Collection of beer-related events
	var beer_events: BeerEvents

	# Where to save the sample email
	var sample_email_path: String

	init(street: String)
	do
		self.street = street
		self.url = "www.brasseriebenelux.com/{street}"
 		self.db_path = "benitlux_{street}.db"
		self.sample_email_path = "benitlux_{street}.email"
	end

	var curl = new Curl
	fun run(send_emails: Bool)
	do
		var body = download_html_page

		fill_beers_from_html(body)
		curl.destroy

		var db = new DB.open(db_path)

		db.insert_beers_of_the_day beers

		beer_events = db.beer_events_today

		generate_email(db)

		# Save as sample email to file
		var f = new OFStream.open(sample_email_path)
		f.write email_title + "\n"
		for line in email_content do f.write line + "\n"
		f.close

		if send_emails then
			var subs = db.subscribers
			send_emails_to subs
		end

		db.close
	end

	fun download_html_page: String
	do
		var request = new CurlHTTPRequest(url, curl)
		var response = request.execute

		if response isa CurlResponseSuccess then
			return response.body_str
		else if response isa CurlResponseFailed then
			print "Failed downloading URL '{url}' with: {response.error_msg} ({response.error_code})"
			exit 1
		end
		abort
	end

	fun fill_beers_from_html(body: String)
	do
		# Parts of the HTML page expected to encapsulate the interesting section
		var header = "<h1>Bières<br /></h1>"
		var ender = "</div></div></div>"

		var match = body.search(header)
		assert match != null else print body
		var start = match.after

		match = body.search_from(ender, start)
		assert match != null
		var finish = match.from

		var of_interest = body.substring(start, finish-start)
		var lines = of_interest.strip_tags.to_clean_lines

		for line in lines do
			var parts = line.split(" - ")
			beers.add new Beer(parts[0].trim,
				parts[1].trim)
		end
	end

	var email_content: Array[String]
	var email_title: String
	fun generate_email(db: Sqlite3DB)
	do
		email_title = beer_events.to_email_title

		email_content = beer_events.to_email_content
	end

	fun send_emails_to(subs: Array[String])
	do
		for email in subs do
			var unsub_link = "http://benitlux.xymus.net/?unsub=&email={email}"
			var content = """
{{{email_content.join("<br />\n")}}}
<br /><br />
To unsubscribe, go to <a href="{{{unsub_link}}}">{{{unsub_link}}}</a>
"""

			var mail = new Mail("Benitlux <benitlux@xymus.net>", email_title, content)
			mail.to.add email
			mail.header["Content-Type"] = "text/html; charset=\"UTF-8\""
			mail.encrypt_with_base64

			mail.send
		end
	end
end

redef class OptionContext
	# Shall we mail the mailing list?
	var send_emails = new OptionBool("Send emails to subscribers", "-e", "--email")

	# Print the usage message
	var help = new OptionBool("Print this help message", "-h", "--help")

	redef init do add_option(send_emails, help)
end

var opts = new OptionContext
opts.parse args
if not opts.errors.is_empty or opts.help.value == true then
	print opts.errors.join("\n")
	print "Usage: benitlux_daily [Options]"
	opts.usage
	exit 1
end

# Only the Benelux on Sherbrooke publishes its beer menu... for now...
var ben = new Benitlux("sherbrooke")
ben.run(opts.send_emails.value or else false)
