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
    #assumption: if there are multiple stages found and customer didn't specify the stage, then return directly without providing any data
    #if there's only one stage, then return the only one and stage can be empty and customers don't need to specify it.
    #if stage is not null, get the spear_refs for the specific stage or else return all of the refs found
    if node_size > 1 && stage.empty?
      string_to_output = "There are multiple stages for plan_number: #{plan_number}, please specify a stage number, e.g. stage 18"
      puts string_to_output
      File.open("output/multiple_stages_warning.txt", "a") {|f| f.puts string_to_output }
      return {}
    end

    #index is from 1 to node_size: get all of the addresses and ref numbers here:
    spear_refs = (1..node_size).inject({:plan_number => plan_number, :addresses => [], :refs => []}) do |refs, i|
      refs[:addresses] << (doc.xpath("//*[@id='grid_1']/div[2]/div/div[#{i}]/div[1]/div[2]/div/div/a[1]/span").text)  #row 1
      refs[:refs] << (doc.xpath("//*[@id='grid_1']/div[2]/div/div[#{i}]/div[9]/div[2]/div/span").text) #column 9
      refs
    end
    puts spear_refs

    unless stage.empty?
      addresses = []
      refs = []
      spear_refs.values_at(:addresses, :refs).transpose.each do |addr, ref|
        if addr.downcase.include?(stage.downcase)
          addresses << addr
          refs  << ref
        end
      end
      spear_refs[:addresses], spear_refs[:refs] = addresses, refs
    end
    spear_refs
  end

  def get_milestone_info_by_spear_ref(spear_refs = {})
    #concate the ref number with milestone url prefix and parse that page to get the milestone information
    return [] if spear_refs.empty?

    completed_info = []
    spear_refs.values_at(:addresses, :refs).transpose.each do |addr, ref|
      milestone_url =  MILESTONE_URL_PREFIX + ref
      browser = Watir::Browser.new #after close, have to new one again
      # puts milestone_url
      browser.goto milestone_url
      doc = Nokogiri::HTML(browser.html)
      #count of the rows of milestone table
      total_rows = doc.xpath('//*[@id="sid003_milestones_list"]/tbody/tr').size - 1

      completed = {:plan_number => spear_refs[:plan_number], :address => addr, :completed => [] }
      (1..total_rows).each do |i|
        image = doc.xpath("//*[@id='sid003_milestones_list']/tbody/tr[#{i}]/td[1]/img")[0][:src]
        if image.include?("/images/iconcomplete") #for those ticked boxes, using the iconcomplete image
          stage = doc.xpath("//*[@id='sid003_milestones_list']/tbody/tr[#{i}]/td[2]/p").text.strip.chomp
          date = doc.xpath("//*[@id='sid003_milestones_list']/tbody/tr[#{i}]/td[3]/p").text.strip.chomp
          completed[:completed] << "#{stage} #{date}"
        end
      end
      completed_info << completed

      browser.close
    end if spear_refs[:refs]
    completed_info
  end


end

