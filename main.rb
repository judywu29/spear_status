require_relative 'spear_status'
require 'yaml' # Built in, no gem required

require 'csv'
#grid_1 > div.ngViewport.ng-scope > div > div:nth-child(1) > div.ngCell.PROPERTY_CellClass.col0.colt0 > div:nth-child(2) > div

# spear_status = SpearStatus.new
# status = spear_status.get_status('PS611333', 'stage 18')
# status = spear_status.get_status('PS736949')
# status = spear_status.get_status('PS611333')
#
# puts status.inspect
if $0 == __FILE__

  #read the file name from the stdin and check the argument: file name has to be exist
  if ARGV.length < 1
    puts "Usage: #$0 <input file including plan number>"
    exit(1)
  end

  plan_number_file = ARGV[0]

  #check the existance of the file
  unless File.exist?(plan_number_file)
    puts "#{plan_number_file} is not exist."
    exit(1)
  end

  puts "Welcome to spear status searching"
  spear_status = SpearStatus.new
  all_content = File.read(plan_number_file)
  plan_numbers = all_content.split(",")
  all_status = []
  plan_numbers.each do |plan_number|
    status = spear_status.get_status(plan_number)
    all_status += status
  end

  # spear_status.write_to_file(all_status)


  # File.open("output/output.yml",'a') { |h| h << YAML.dump(all_status) }
  File.open("output/output.csv",'a') do |f|
    f.puts "Plan number|Address|Milestone"
    data = []
    all_status.each do |hash|
      stage_info = []
      hash[:completed][:stage].each_with_index do |stage, index|
        stage_info << "#{stage} #{hash[:completed][:date][index]}"
      end
      data << hash[:plan_number] << hash[:address] << stage_info.join(";")
      f.puts data.join("|")
    end
  end

end

#PS747366P
#[{:address=>"8 PLAZA COURT, ROXBURGH PARK VIC 3064", :completed=>{:stage=>["Application Submission", "Referral", "Planning Permit"], :date=>["11/02/2016", "17/02/2016", "29/02/2016"]}}]

#PS611333
# [{:address=>"Saltwater Coast Stage 34A (Staged Plan 341), Lachie Grove, Point Cook", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["12/02/2016", "08/03/2016"]}},
#  {:address=>"LACHIE GROVE, POINT COOK VIC 3030", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["12/02/2016", "09/03/2016"]}},
#  {:address=>"Saltwater Coast Stage 35, Lachie Grove, Point Cook", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["12/02/2016", "09/03/2016"]}},
#  {:address=>"LACHIE GROVE, POINT COOK VIC 3030", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["12/02/2016", "09/03/2016"]}},
#  {:address=>"POINT COOK HOMESTEAD ROAD, POINT COOK VIC 3030", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["15/12/2015", "05/01/2016"]}},
#  {:address=>"POINT COOK HOMESTEAD ROAD, POINT COOK VIC 3030", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["25/11/2015", "01/12/2015"]}},
#  {:address=>"POINT COOK HOMESTEAD ROAD, POINT COOK VIC 3030", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["27/11/2015", "01/12/2015"]}},
#  {:address=>"POINT COOK HOMESTEAD ROAD, POINT COOK VIC 3030", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["27/11/2015", "01/12/2015"]}},
#  {:address=>"Saltwater Coast Stage 20", :completed=>{:stage=>["Application Submission", "Referral", "Street Addressing (Submitted on M1)"], :date=>["01/09/2015", "11/09/2015", "14/02/2016"]}},
#  {:address=>"Saltwater Coast Stage 19", :completed=>{:stage=>["Application Submission", "Referral", "Street Addressing (Submitted on M1)"], :date=>["01/09/2015", "11/09/2015", "14/02/2016"]}},
#  {:address=>"Saltwater Coast - Stage 28 - 47 Lot Subdivision", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["10/06/2015", "24/06/2015"]}},
#  {:address=>"Saltwater Stage 32", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["10/06/2015", "22/06/2015"]}},
#  {:address=>"POINT COOK HOMESTEAD ROAD, POINT COOK VIC 3030", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["10/06/2015", "24/06/2015"]}},
#  {:address=>"Saltwater Coast Stage 18", :completed=>{:stage=>["Application Submission", "Referral", "Street Addressing (Submitted on M1)"], :date=>["08/05/2015", "19/05/2015", "09/08/2015"]}},
#  {:address=>"Saltwater Coast Stage 21A - Citybay Drive, Point Cook", :completed=>{:stage=>["Application Submission", "Referral", "Street Addressing (Submitted on M1)"], :date=>["21/11/2014", "28/11/2014", "20/12/2015"]}},
#  {:address=>"Saltwater Coast Stage 26A", :completed=>{:stage=>["Application Submission", "Referral", "Street Addressing (Supplied)"], :date=>["22/11/2013", "11/12/2013", "13/12/2013"]}},
#  {:address=>"Saltwater Coast Stage 221 (22A)", :completed=>{:stage=>["Application Submission", "Referral", "Original Certification Date", "Re-certification (Most Recent)", "Street Addressing (Supplied)"], :date=>["30/10/2012", "07/11/2012", "21/12/2012", "25/08/2014", "07/08/2014"]}},
#  {:address=>"Saltwater Coast Stage 192", :completed=>{:stage=>["Application Submission", "Referral"], :date=>["08/08/2012", "16/08/2012"]}},
#  {:address=>"Saltwater Coast Stage 15", :completed=>{:stage=>["Application Submission", "Referral", "Original Certification Date", "Re-certification (Most Recent)", "Street Addressing (Submitted on M1)"], :date=>["26/07/2010", "03/08/2010", "30/06/2011", "20/07/2015", "21/02/2016"]}},
#  {:address=>"Lot / Plan (S21 / PS611333)", :completed=>{:stage=>["Application Submission", "Referral", "Original Certification Date", "Street Addressing (Submitted on M1)"], :date=>["24/11/2009", "27/11/2009", "17/09/2015", "20/09/2015"]}},
#  {:address=>"Lot / Plan (S17 / PS611333Q)", :completed=>{:stage=>["Application Submission", "Referral", "Street Addressing (Supplied)"], :date=>["13/07/2009", "30/07/2009", "17/10/2013"]}}]

#
# [{:address=>"WINDSOR STREET, WODONGA VIC 3690", :completed=>{:stage=>["Application Submission", "Referral", "Final Referral Response (Cert)", "Original Certification Date", "Re-certification (Most Recent)", "Street Addressing (Supplied)"], :date=>["30/01/2015", "23/02/2015", "14/04/2015", "14/04/2015", "04/08/2015", "11/03/2015"]}}]
