require 'rubygems' # Unless you install from the tarball or zip.
require 'icalendar'
require 'date'
require 'open-uri'

include Icalendar # Probably do this in your class to limit namespace overlap

# Open a file or pass a string to the parser
cal_url = ARGV[0]

if(cal_url.nil?) 
	puts "No calendar given"
	exit
end

puts "Opening calendar: "+cal_url

cal_contents = web_contents  = open(cal_url) {|f| f.read }

# Parser returns an array of calendars because a single file
# can have multiple calendars.
cals = Icalendar.parse(cal_contents)
cal = cals.first

# Now you can access the cal object in just the same way I created it
projectHours = {}
subprojectHours = {}

maxEnd = nil
minStart = nil

cal.events.each do |event|
	maxEnd = event.dtend if maxEnd.nil? or maxEnd < event.dtend
	minStart = event.dtstart if minStart.nil? or minStart > event.dtstart
	
	res = (event.dtend - event.dtstart).to_f * 24
	
	project, sep, subproject, sep, desc = event.summary.split(/(:|\/)/)
	
	project = "" if project.nil?
	subproject = "" if subproject.nil?
	desc = "" if desc.nil?
	
	project = project.downcase
	subproject = subproject.downcase unless subproject.nil?

	unless projectHours[project].nil? 
		projectHours[project] += res 
	else 
		projectHours[project] = res 
		subprojectHours[project] = {}
	end

	unless subprojectHours[project][subproject].nil? 
		subprojectHours[project][subproject] += res 
	else 
		subprojectHours[project][subproject] = res 
	end
end

total = 0
projectHours.each do |key, val|
	total += val
	puts key + ": " + val.to_s
	subprojectHours[key].each do |subproject, val|
		puts "  - " + (subproject.nil? or subproject == "" ? "else" : subproject) + ": " + val.to_s
	end
end

numDays = (maxEnd - minStart).to_i;
numDays -= (numDays / 7) * 2
numWeeks = (maxEnd.cweek - minStart.cweek)

puts "#{minStart} to #{maxEnd}"
puts "#{numDays} days, #{numWeeks} weeks"
puts "#{total} hours"
puts "#{total / numDays} hrs/day" 
puts "#{total / numWeeks} hrs/week" 

