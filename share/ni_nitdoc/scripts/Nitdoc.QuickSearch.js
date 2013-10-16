/* This file is part of NIT ( http://www.nitlanguage.org ).

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Documentation generator for the nit language.
   Generate API documentation in HTML format from nit source code.
*/

var Nitdoc = Nitdoc || {};

/*
 * Nitdoc QuickSearch module
 *
 */

Nitdoc.QuickSearch = function() {
	var rawList = nitdocQuickSearchRawList; // List of raw resulsts generated by nitdoc tool
	var searchField = null; // <input:text> search field
	var currentTable = null; // current search results <table>
	var currentIndex = -1; // current cursor position into search results table

	// Enable QuickSearch plugin
	var enableQuickSearch = function(containerSelector) {
		searchField = $(document.createElement("input"))
		.attr({
			id: "nitdoc-qs-field",
			type: "text",
			autocomplete: "off",
			value: "quick search..."
		})
		.addClass("nitdoc-qs-field-notused")
		.keyup(function(event) {
			Nitdoc.QuickSearch.doKeyAction(event.keyCode);
		})
		.focusout(function() {
			if($(this).val() == "") {
				$(this).addClass("nitdoc-qs-field-notused");
				$(this).val("quick search...");
			}
		})
		.focusin(function() {
			if($(this).val() == "quick search...") {
				$(this).removeClass("nitdoc-qs-field-notused");
				$(this).val("");
			}
		});

		$(containerSelector).append(
			$(document.createElement("li"))
			.attr("id", "nitdoc-qs-li")
			.append(searchField)
		);

		// Close quicksearch list on click
		$(document).click(function(e) {
			Nitdoc.QuickSearch.closeResultsTable();
		});
	}

	// Respond to key event
	var doKeyAction = function(key) {
		switch(key) {
			case 38: // Up
				selectPrevResult();
			break;

			case 40: // Down
				selectNextResult();
			break;

			case 13: // Enter
				goToResult();
				return false;
			break;

			case 27: // Escape
				$(this).blur();
				closeResultsTable();
			break;

			default: // Other keys
				var query = searchField.val();
				if(!query) {
					return false;
				}
				var results = rankResults(query);
				results.sort(resultsSort);
				displayResultsTable(query, results);
			break;
		}
	}

	// Rank raw list entries corresponding to query
	var rankResults = function(query) {
		var results = new Array();
		for(var entry in rawList) {
			for(var i in rawList[entry]) {
				var result = rawList[entry][i];
				result.entry = entry;
				result.distance = query.dice(entry);
				results[results.length] = result;
			}
		}
		return results;
	}

	// Sort an array of results
	var resultsSort = function(a, b){
		if(a.distance < b.distance) {
			return 1;
		} else if(a.distance > b.distance) {
			return -1;
		}
		return 0;
	}

	// Display results in a popup table
	var displayResultsTable = function(query, results) {
		// Clear results table
		if(currentTable) currentTable.remove();

		// Build results table
		currentIndex = -1;
		currentTable = $(document.createElement("table"));

		for(var i in results) {
			if(i > 10) {
				break;
			}
			var result = results[i];
			currentTable.append(
				$(document.createElement("tr"))
				.data("searchDetails", {name: result.entry, url: result.url})
				.data("index", i)
				.append($(document.createElement("td")).html(result.entry))
				.append(
					$(document.createElement("td"))
						.addClass("nitdoc-qs-info")
						.html(result.txt + "&nbsp;&raquo;")
				)
				.mouseover( function() {
					$(currentTable.find("tr")[currentIndex]).removeClass("nitdoc-qs-active");
					$(this).addClass("nitdoc-qs-active");
					currentIndex = $(this).data("index");
				})
				.mouseout( function() {
					$(this).removeClass("nitdoc-qs-active");
				 })
				.click( function() {
					window.location = $(this).data("searchDetails")["url"];
				})
			);
		}
		currentTable.append(
			$("<tr class='nitdoc-qs-overflow'>")
			.append(
				$("<td colspan='2'>")
				.html("Best results for '" + query + "'")
			)
		);

		// Initialize table properties
		currentTable.attr("id", "nitdoc-qs-table");
		currentTable.css("position", "absolute");
		currentTable.width(searchField.outerWidth());
		$("body").append(currentTable);
		currentTable.offset({left: searchField.offset().left + (searchField.outerWidth() - currentTable.outerWidth()), top: searchField.offset().top + searchField.outerHeight()});
		// Preselect first entry
		if(currentTable.find("tr").length > 0) {
			currentIndex = 0;
			$(currentTable.find("tr")[currentIndex]).addClass("nitdoc-qs-active");
			searchField.focus();
		}
	}

	// Select the previous result on current table
	var selectPrevResult = function() {
		// If already on first result, focus search input
		if(currentIndex == 0) {
			searchField.val($(currentTable.find("tr")[currentIndex]).data("searchDetails").name);
			searchField.focus();
		// Else select previous result
		} else if(currentIndex > 0) {
			$(currentTable.find("tr")[currentIndex]).removeClass("nitdoc-qs-active");
			currentIndex--;
			$(currentTable.find("tr")[currentIndex]).addClass("nitdoc-qs-active");
			searchField.val($(currentTable.find("tr")[currentIndex]).data("searchDetails").name);
			searchField.focus();
		}
	}

	// Select the next result on current table
	var selectNextResult = function() {
		if(currentIndex < currentTable.find("tr").length - 1) {
			if($(currentTable.find("tr")[currentIndex + 1]).hasClass("nitdoc-qs-overflow")) {
				return;
			}
			$(currentTable.find("tr")[currentIndex]).removeClass("nitdoc-qs-active");
			currentIndex++;
			$(currentTable.find("tr")[currentIndex]).addClass("nitdoc-qs-active");
			searchField.val($(currentTable.find("tr")[currentIndex]).data("searchDetails").name);
			searchField.focus();
		}
	}

	// Load selected search result page
	var goToResult = function() {
		if(currentIndex > -1) {
			window.location = $(currentTable.find("tr")[currentIndex]).data("searchDetails").url;
			return;
		}

		if(searchField.val().length == 0) { return; }

		window.location = "search.html#q=" + searchField.val();
		if(window.location.href.indexOf("search.html") > -1) {
			location.reload();
		}
	}

	// Close the results table
	closeResultsTable = function(target) {
		if(target != searchField && target != currentTable) {
			if(currentTable != null) {
				currentTable.remove();
				currentTable = null;
			}
		}
	}

	// Public interface
	var quicksearch = {
		enableQuickSearch: enableQuickSearch,
		doKeyAction: doKeyAction,
		closeResultsTable: closeResultsTable
	};

	return quicksearch;
}();

$(document).ready(function() {
	Nitdoc.QuickSearch.enableQuickSearch("nav.main ul");
});

/*
 * Utils
 */

// Calculate levenshtein distance beetween two strings
// see: http://en.wikipedia.org/wiki/Levenshtein_distance
String.prototype.levenshtein = function(other) {
	var matrix = new Array();

	for(var i = 0; i <= this.length; i++) {
		matrix[i] = new Array();
		matrix[i][0] = i;
	}
	for(var j = 0; j <= other.length; j++) {
		matrix[0][j] = j;
	}
	var cost = 0;
	for(var i = 1; i <= this.length; i++) {
		for(var j = 1; j <= other.length; j++) {
			if(this.charAt(i - 1) == other.charAt(j - 1)) {
				cost = 0;
			} else if(this.charAt(i - 1).toLowerCase() == other.charAt(j - 1).toLowerCase()) {
				cost = 0.5;
			} else {
				cost = 1;
			}
			matrix[i][j] = Math.min(
				matrix[i - 1][j] + 1, // deletion
				matrix[i][j - 1] + 1, // insertion
				matrix[i - 1][j - 1] + cost // substitution
			);
		}
	}
	return matrix[this.length][other.length]
}

// Compare two strings using Sorensen-Dice Coefficient
// see: http://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient
String.prototype.dice = function(other) {
	var length1 = this.length - 1;
	var length2 = other.length - 1;
	if(length1 < 1 || length2 < 1) return 0;

	var bigrams2 = [];
	for(var i = 0; i < length2; i++) {
		bigrams2.push(other.substr(i, 2));
	}

	var intersection = 0;
	for(var i = 0; i < length1; i++) {
		var bigram1 = this.substr(i, 2);
		for(var j = 0; j < length2; j++) {
			if(bigram1 == bigrams2[j]) {
				intersection += 2;
				bigrams2[j] = null;
				break;
			} else if (bigram1 && bigrams2[j] && bigram1.toLowerCase() == bigrams2[j].toLowerCase()) {
				intersection += 1;
				bigrams2[j] = null;
				break;
			}
		}
	}
	return (2.0 * intersection) / (length1 + length2);
}
