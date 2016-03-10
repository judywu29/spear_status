require 'watir-webdriver'
require 'headless'
require 'nokogiri'


class SpearStatus

  SPEAR_URL = 'https://www.spear.land.vic.gov.au/spear/publicSearch/Search.do'
  MILESTONE_URL_PREFIX = "https://www.spear.land.vic.gov.au/spear/applicationDetails/RetrievePublicApplication.do?cacheApplicationListContext=true&spearNum="

  def initialize
    @headless = Headless.new
    @headless.start

  end

  def destroy
    @headless.destroy
  end

  def get_status(plan_number = "", stage = "")
    #steps to get the status: first fill the form with plan number and get the response page
    #then parse the response page to get all the property addresses or stages and reference number(to concate the url)
    #and finally go to that url to get the completed milestone information(stage and date)
    return [] if plan_number.empty?

    res_page = submit_form(plan_number)
    spear_refs = get_spear_refs_after_submit(plan_number, res_page, stage)
    return get_milestone_info_by_spear_ref(spear_refs)
  end

  def write_to_file(info_to_write = [])
    File.open("output/output.yml",'w+') do |h|
      h << YAML.dump(info_to_write)
    end
  end

  private
  def submit_form(plan_number = "")
    #fill the form with plan number and submit the form, return the response html page
    browser = Watir::Browser.new
    browser.goto SPEAR_URL
    browser.text_field(:id => 'planNumber').set plan_number
    browser.button(:value => 'search').click

    sleep(20) # to wait for the js execution

    page = browser.html
    browser.close
    page
  end

  def get_spear_refs_after_submit(plan_number, res_page, stage = "")
    #parse the response html page and get the addresses and ref number
    return {} if res_page.nil?

    doc = Nokogiri::HTML(res_page)
    node_size = doc.xpath('//*[@id="grid_1"]/div[2]/div').children.size - 3 #3 are other nodes not to use
    #index is from 1 to node_size:
    spear_refs = (1..node_size).inject({:addresses => [], :refs => []}) do |refs, i|
      refs[:addresses] << (doc.xpath("//*[@id='grid_1']/div[2]/div/div[#{i}]/div[1]/div[2]/div/div/a[1]/span").text)  #row 1
      refs[:refs] << (doc.xpath("//*[@id='grid_1']/div[2]/div/div[#{i}]/div[9]/div[2]/div/span").text) #column 9

      refs
    end
    puts spear_refs
    #assumption: if there are multiple stages found and customer didn't specify the stage, then return directly and fails
    #if there's only one stage, then return the only one and stage can be empty and customers don't need to specify it.
    #if stage is not null, get the spear_refs for the specific stage or else return all of the refs found
    if node_size > 1 && stage.empty?
      string_to_output = "There are multiple stages for plan_number: #{plan_number}, please specify a stage number, e.g. stage 18"
      puts string_to_output
      File.open("output/multiple_stages_warning.txt", "a") {|f| f.puts string_to_output }

      return {}
    end

    unless stage.empty?
      spear_refs[:addresses].each_with_index do |addr, i|
        if addr.downcase.include?(stage.downcase)
          spear_refs[:refs]  = [spear_refs[:refs][i]]
          spear_refs[:addresses] = [spear_refs[:addresses][i]]
          break
        end
      end
    end
    spear_refs
  end

  def get_milestone_info_by_spear_ref(spear_refs = {})
    #concate the ref number with milestone url prefix and parse that page to get the milestone information
    return [] if spear_refs.empty?

    completed_info = []
    spear_refs[:refs].each_with_index do |ref, index|
      milestone_url =  MILESTONE_URL_PREFIX + ref
      browser = Watir::Browser.new
      # puts milestone_url
      browser.goto milestone_url
      doc = Nokogiri::HTML(browser.html)
      #count of the rows of milestone table
      total_rows = doc.xpath('//*[@id="sid003_milestones_list"]/tbody/tr').size - 1

      completed = {:address => spear_refs[:addresses][index], :completed => {:stage => [], :date => [] } }
      (1..total_rows).each do |i|
        image = doc.xpath("//*[@id='sid003_milestones_list']/tbody/tr[#{i}]/td[1]/img")[0].to_s
        if image.include?("iconcomplete")
          completed[:completed][:stage] << doc.xpath("//*[@id='sid003_milestones_list']/tbody/tr[#{i}]/td[2]/p").text.strip.chomp
          completed[:completed][:date] << doc.xpath("//*[@id='sid003_milestones_list']/tbody/tr[#{i}]/td[3]/p").text.strip.chomp
        end
      end
      completed_info << completed

      browser.close
    end if spear_refs[:refs]
    completed_info
  end


end

#grid_1 > div.ngViewport.ng-scope > div > div:nth-child(1) > div.ngCell.PROPERTY_CellClass.col0.colt0 > div:nth-child(2) > div

# spear_status = SpearStatus.new
# status = spear_status.get_status('PS611333', 'stage 18')
# status = spear_status.get_status('PS736949')
# status = spear_status.get_status('PS611333')
status =
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
  plan_numbers = all_content.split(",")[0..49]
  all_status = []
  plan_numbers.each do |plan_number|
    status = spear_status.get_status(plan_number)
    all_status += status
  end

  spear_status.write_to_file(all_status)


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
