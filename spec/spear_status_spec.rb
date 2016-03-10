require 'spec_helper'
require_relative '../spear_status'

describe SpearStatus do
  before(:all) do
    @spear_status = SpearStatus.new
  end
  after(:all) do
    @spear_status.destroy
  end

  describe "#submit_form" do
    context "with valid plan number and url" do
      it "returns a string with html code" do
        result = @spear_status.send :submit_form, 'PS747366P'
        expect(result).not_to be_nil

        doc = Nokogiri::HTML(result)
        expect(doc.xpath('//*[@id="grid_1"]/div[2]/div').children.size).to eq 4
      end
    end
  end

  describe "#get_spear_refs_after_submit" do
    before(:each) do
      @browser = Watir::Browser.new
    end
    after(:each) do
      @browser.close
    end

    it "gets one ref number" do
      PS747366P_url = 'https://www.spear.land.vic.gov.au/spear/applicationList/PublicSearchSubmit.do?spearRef=&planNumber=PS747366P&councilName=&councilRef=&streetName=&method=search'
      @browser.goto PS747366P_url
      sleep 15
      result = @spear_status.send :get_spear_refs_after_submit, 'PS747366P', @browser.html
      expect(result).to eq(:addresses=>["8 PLAZA COURT, ROXBURGH PARK VIC 3064"], :refs=>["S080799A"])
    end

    it "returns empty hash if there are multiple stages but no stage provided" do
      PS611333_url = 'https://www.spear.land.vic.gov.au/spear/applicationList/PublicSearchSubmit.do?spearRef=&planNumber=PS611333&councilName=&councilRef=&streetName=&method=search'
      @browser.goto PS611333_url
      sleep 15
      result = @spear_status.send :get_spear_refs_after_submit, 'PS611333', @browser.html
      expect(result).to be_empty
    end

    it "returns the specific ref for the specific stage" do
      PS611333_url = 'https://www.spear.land.vic.gov.au/spear/applicationList/PublicSearchSubmit.do?spearRef=&planNumber=PS611333&councilName=&councilRef=&streetName=&method=search'
      @browser.goto PS611333_url
      sleep 15
      result = @spear_status.send :get_spear_refs_after_submit, 'PS611333', @browser.html, 'stage 18'
      expect(result).to eq(:addresses=>["Saltwater Coast Stage 18"], :refs=>["S067474J"])

    end

  end

  describe "#get_milestone_info_by_spear_ref" do
    context "with empty spear_refs" do
      it "returns empty array" do
        expect(@spear_status.send :get_milestone_info_by_spear_ref).to be_empty
      end
    end
    context "with valid spear refs" do
      it "returns milestone information" do
        spear_refs = { :addresses=>["Saltwater Coast Stage 18"], :refs=>["S067474J"] }
        result = @spear_status.send :get_milestone_info_by_spear_ref, spear_refs
        expect(result.size).to eq 1
        expect(result).to include({:address=>"Saltwater Coast Stage 18", :completed=>{:stage=>["Application Submission", "Referral", "Street Addressing (Submitted on M1)"], :date=>["08/05/2015", "19/05/2015", "09/08/2015"]}})

      end
    end
  end

  describe "#get_status" do
    context "with empty plan number" do
      it "returns nil" do
        expect(@spear_status.get_status).to be_empty
      end
    end
    context "with valid plan number" do
      it "returns result" do
        plan_number = 'PS611333'
        html_string = "blabla.."
        allow(@spear_status).to receive(:submit_form).with(plan_number).and_return(html_string)
        spear_refs = {:addresses=>["Saltwater Coast Stage 18"], :refs=>["S067474J"]}
        allow(@spear_status).to receive(:get_spear_refs_after_submit).with(plan_number, html_string, '').and_return(spear_refs)
        status = [{:address=>"Saltwater Coast Stage 18", :completed=>{:stage=>["Application Submission", "Referral", "Street Addressing (Submitted on M1)"], :date=>["08/05/2015", "19/05/2015", "09/08/2015"]}}]
        allow(@spear_status).to receive(:get_milestone_info_by_spear_ref).with(spear_refs).and_return(status)
        expect(@spear_status.get_status('PS611333')).to eq status
      end

    end
  end
end