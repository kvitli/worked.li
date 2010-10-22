require 'rubygems' 
require 'icalendar'
require 'date'
require 'open-uri'

include Icalendar

cal_url = ARGV[0]

if(cal_url.nil?) 
	puts "No calendar given"
	exit
end

puts "Opening calendar: "+cal_url

cal_contents = web_contents  = open(cal_url) {|f| f.read }

cals = Icalendar.parse(cal_contents)
cal = cals.first

projectHours = {}
taskHours = {}

maxEnd = nil
minStart = nil

class Transaction 
	attr_accessor :project, :task, :hours, :description
	
	def self.fromEvent(event)
		ret = Transaction.new
		ret.hours = (event.dtend - event.dtstart).to_f * 24
		ret.project, ret.task, ret.description = parse(event.summary)
		return ret
	end
	
	def self.parse(string)
		project, sep, task, sep, desc = string.split(/(:|\/)/)
	
		project = "" if project.nil?
		task = "" if task.nil?
		desc = "" if desc.nil?
	
		project = project.downcase
		task = task.downcase unless task.nil?

		return project, task, desc
	end 
end

cal.events.each do |event|
	maxEnd = event.dtend if maxEnd.nil? or maxEnd < event.dtend
	minStart = event.dtstart if minStart.nil? or minStart > event.dtstart
	
	t = Transaction.fromEvent(event)
	
	unless projectHours[t.project].nil? 
		projectHours[t.project] += t.hours 
	else 
		projectHours[t.project] = t.hours 
		taskHours[t.project] = {}
	end

	unless taskHours[t.project][t.task].nil? 
		taskHours[t.project][t.task] += t.hours 
	else 
		taskHours[t.project][t.task] = t.hours 
	end
end

total = 0
projectHours.each do |key, val|
	total += val
	puts key + ": " + val.to_s
	taskHours[key].each do |task, val|
		puts "  - " + (task.nil? or task == "" ? "else" : task) + ": " + val.to_s
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

