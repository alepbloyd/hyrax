require 'spec_helper'

describe GenericFile do
  before(:each) do 
    @file = GenericFile.new
  end 


  it "should have rightsMetadata" do
    @file.rightsMetadata.should be_instance_of Hydra::Datastream::RightsMetadata
  end
  it "should have apply_depositor_metadata" do
    @file.apply_depositor_metadata('jcoyne')
    @file.rightsMetadata.edit_access.should == ['jcoyne']
  end
  it "should have a characterization datastream" do
    @file.characterization.should be_kind_of FitsDatastream
  end 
  it "should have a dc desc metadata" do
    @file.descMetadata.should be_kind_of GenericFileRdfDatastream
  end
  it "should have content datastream" do
    @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
    @file.content.should be_kind_of FileContentDatastream
  end
  describe "delegations" do
    it "should delegate methods to descriptive metadata" do
      @file.should respond_to(:related_url)
      @file.should respond_to(:based_near)
      @file.should respond_to(:part_of)
      @file.should respond_to(:contributor)
      @file.should respond_to(:creator)
      @file.should respond_to(:title)
      @file.should respond_to(:description)
      @file.should respond_to(:publisher)
      @file.should respond_to(:date_created)
      @file.should respond_to(:date_uploaded)
      @file.should respond_to(:date_modified)
      @file.should respond_to(:subject)
      @file.should respond_to(:language)
      @file.should respond_to(:date)
      @file.should respond_to(:rights)
      @file.should respond_to(:resource_type)
      @file.should respond_to(:format)
      @file.should respond_to(:identifier)
    end
    it "should delegate methods to characterization metadata" do
      @file.should respond_to(:format_label)
      @file.should respond_to(:mime_type)
      @file.should respond_to(:file_size)
      @file.should respond_to(:last_modified)
      @file.should respond_to(:filename)
      @file.should respond_to(:original_checksum)
      @file.should respond_to(:well_formed)
      @file.should respond_to(:file_title)
      @file.should respond_to(:file_author)
      @file.should respond_to(:page_count)
    end
    it "should be able to set values via delegated methods" do
      @file.related_url = "http://example.org/"
      @file.creator = "John Doe"
      @file.title = "New work"
      @file.save
      f = GenericFile.find(@file.pid)
      f.related_url.should == ["http://example.org/"]
      f.creator.should == ["John Doe"]
      f.title.should == ["New work"]
      @file.delete     
    end
    it "should be able to be added to w/o unexpected graph behavior" do
      @file.creator = "John Doe"
      @file.title = "New work"
      @file.save
      f = GenericFile.find(@file.pid)
      f.creator.should == ["John Doe"]
      f.title.should == ["New work"]
      f.creator = "Jane Doe"
      f.title << "Newer work"
      f.save
      f = GenericFile.find(@file.pid)
      f.creator.should == ["Jane Doe"]
      f.title.should == ["New work", "Newer work"]
      @file.delete
    end
  end
  it "should support to_solr" do
    @file.part_of = "Arabiana"
    @file.contributor = "Mohammad"
    @file.creator = "Allah"
    @file.title = "The Work"
    @file.description = "The work by Allah"
    @file.publisher = "Vertigo Comics"
    @file.date_created = "1200"
    @file.date_uploaded = "2011"
    @file.date_modified = "2012"
    @file.subject = "Theology"
    @file.language = "Arabic"
    @file.rights = "Wide open, buddy."
    @file.resource_type = "Book"
    @file.format = "application/pdf"
    @file.identifier = "urn:isbn:1234567890"
    @file.based_near = "Medina, Saudi Arabia"
    @file.related_url = "http://example.org/TheWork/"
    @file.save
    @file.to_solr.should_not be_nil
    @file.to_solr["generic_file__part_of_t"].should be_nil
    @file.to_solr["generic_file__date_uploaded_t"].should be_nil
    @file.to_solr["generic_file__date_modified_t"].should be_nil
    @file.to_solr["generic_file__rights_t"].should be_nil
    @file.to_solr["generic_file__related_url_t"].should be_nil
    @file.to_solr["generic_file__contributor_t"].should == ["Mohammad"]
    @file.to_solr["generic_file__creator_t"].should == ["Allah"]
    @file.to_solr["generic_file__title_t"].should == ["The Work"]
    @file.to_solr["generic_file__description_t"].should == ["The work by Allah"]
    @file.to_solr["generic_file__publisher_t"].should == ["Vertigo Comics"]
    @file.to_solr["generic_file__subject_t"].should == ["Theology"]
    @file.to_solr["generic_file__language_t"].should == ["Arabic"]
    @file.to_solr["generic_file__date_created_t"].should == ["1200"]
    @file.to_solr["generic_file__resource_type_t"].should == ["Book"]
    @file.to_solr["generic_file__format_t"].should == ["application/pdf"]
    @file.to_solr["generic_file__identifier_t"].should == ["urn:isbn:1234567890"]
    @file.to_solr["generic_file__based_near_t"].should == ["Medina, Saudi Arabia"]
    @file.delete
  end
  describe "audit" do
    before(:each) do
      @f = GenericFile.new
      @f.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @f.save
      Delayed::Worker.new.work_off 
      @f = GenericFile.find(@f.pid)    
           
    end
    after(:each) do
      @f.delete
    end
    it "should log a failing audit" do
      FileContentDatastream.any_instance.expects(:dsChecksumValid).returns(false)
      FitsDatastream.any_instance.expects(:dsChecksumValid).returns(false)
      ActiveFedora::RelsExtDatastream.any_instance.expects(:dsChecksumValid).returns(false)
      ActiveFedora::Datastream.any_instance.expects(:dsChecksumValid).returns(false)
      GenericFileRdfDatastream.any_instance.expects(:dsChecksumValid).returns(false) #<AnyInstance:>.dsChecksumValid()
      
      ChecksumAuditLog.expects(:create!).with(:pass => false, :pid => @f.pid, :version => 'descMetadata.0', :dsid => 'descMetadata')
      ChecksumAuditLog.expects(:create!).with(:pass => false, :pid => @f.pid, :version => 'DC1.0', :dsid => 'DC')
      ChecksumAuditLog.expects(:create!).with(:pass => false, :pid => @f.pid, :version=>'content.0', :dsid => 'content')
      ChecksumAuditLog.expects(:create!).with(:pass => false, :pid => @f.pid, :version=>'characterization.0', :dsid => 'characterization')
      ChecksumAuditLog.expects(:create!).with(:pass => false, :pid => @f.pid, :version=>'RELS-EXT.0', :dsid => 'RELS-EXT')
      @f.audit!
    end
    it "should log a passing audit" do
      FileContentDatastream.any_instance.expects(:dsChecksumValid).returns(true)
      ChecksumAuditLog.expects(:create!).with(:pass => true, :pid => @f.pid, :version => 'descMetadata.0', :dsid => 'descMetadata')
      ChecksumAuditLog.expects(:create!).with(:pass => true, :pid => @f.pid, :version => 'DC1.0', :dsid => 'DC')
      ChecksumAuditLog.expects(:create!).with(:pass => true, :pid => @f.pid, :version=>'content.0', :dsid => 'content')
      ChecksumAuditLog.expects(:create!).with(:pass => true, :pid => @f.pid, :version=>'characterization.0', :dsid => 'characterization')
      ChecksumAuditLog.expects(:create!).with(:pass => true, :pid => @f.pid, :version=>'RELS-EXT.0', :dsid => 'RELS-EXT')
      @f.audit!
    end
    it "should return true on audit_status" do
      @f.audit_stat.should be_true 
    end
  end

  describe "characterize" do
    before(:each) do 
      @job_count = Delayed::Job.count
    end 
    it "should run when the content datastream is created" do
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @file.save
      Delayed::Job.count.should == @job_count+1
      Delayed::Worker.new.work_off 
      Delayed::Job.count.should == @job_count
      @file.delete
    end
    it "should return expected results when called" do
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @file.characterize
      doc = Nokogiri::XML.parse(@file.characterization.content)
      doc.root.xpath('//ns:imageWidth/text()', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).inner_text.should == '50'
    end
    it "should return expected results after a save" do
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @file.save
      Delayed::Job.count.should == @job_count+1
      Delayed::Worker.new.work_off 
      Delayed::Job.count.should == @job_count
      @file = GenericFile.find(@file.pid)    
      @file.file_size.should == ['4218']
      @file.original_checksum.should == ['28da6259ae5707c68708192a40b3e85c']
      @file.delete
    end
    it "should return a hash of all populated values from the characterization terminology" do
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @file.save
      Delayed::Job.count.should == @job_count+1
      Delayed::Worker.new.work_off 
      Delayed::Job.count.should == @job_count
      @file = GenericFile.find(@file.pid)    
      @file.characterization_terms[:format_label].should == ["Portable Network Graphics"]
      @file.characterization_terms[:mime_type].should == ["image/png"]
      @file.characterization_terms[:file_size].should == ["4218"]
      @file.characterization_terms[:original_checksum].should == ["28da6259ae5707c68708192a40b3e85c"]
      @file.characterization_terms.keys.should include(:last_modified)
      @file.characterization_terms.keys.should include(:filename)
      @file.delete
    end
    it "should return a hash of all populated values from the characterization terminology 2" do
      @file.title.should == []
      @file.resource_type.should == []
      @file.format.should == []
      @file.identifier.should == []
      @file.date_modified.empty?.should be_true
      @file.title.should == []
      @file.add_file_datastream(File.new(Rails.root + 'test_support/fixtures/scholarsphere/scholarsphere_test4.pdf'), :dsid=>'content')
      @file.save
      Delayed::Job.count.should == @job_count+1
      Delayed::Worker.new.work_off 
      Delayed::Job.count.should == @job_count
      @file = GenericFile.find(@file.pid)    
      @file.format_label.should == ["Portable Document Format"]
      @file.format_label.should == ["Portable Document Format"]
      @file.mime_type.should == ["application/pdf"]
      @file.file_size.should == ["218882"]
      #@file.identifier.should == ["5a2d761cab7c15b2b3bb3465ce64586d"]
      #@file.date_modified.empty?.should be_false
      @file.title.should == ["Microsoft Word - sample.pdf.docx"]
      @file.delete
    end

    it "should append metadata from the characterization" do
      #@file.resource_type.should == []
      #@file.format.should == []
      #@file.identifier.should == []
      #@file.date_modified.empty?.should be_true
      #@file.title.should == []
      @file.add_file_datastream(File.new(Rails.root + 'test_support/fixtures/scholarsphere/scholarsphere_test4.pdf'), :dsid=>'content')
      @file.save
      Delayed::Job.count.should == @job_count+1
      Delayed::Worker.new.work_off 
      Delayed::Job.count.should == @job_count
      @file = GenericFile.find(@file.pid) 
      logger.info "File: #{@file.inspect}"   
      @file.format_label.should == ["Portable Document Format"]
      @file.resource_type.should == ["Portable Document Format"]
      @file.format.should == ["application/pdf"]
      @file.identifier.should == ["5a2d761cab7c15b2b3bb3465ce64586d"]
      @file.date_modified.empty?.should be_false
      @file.title.should == ["Microsoft Word - sample.pdf.docx"]
      @file.delete
    end
  end
  describe "label" do
    it "should set the inner label" do
      @file.label = "My New Label"
      @file.inner_object.label.should == "My New Label"
    end
  end

  context "with rightsMetadata" do
    subject do
      m = GenericFile.new()
      m.rightsMetadata.update_permissions("person"=>{"person1"=>"read","person2"=>"discover"}, "group"=>{'group-6' => 'read', "group-7"=>'read', 'group-8'=>'edit'})
      m.save
      m
    end
    it "should have read groups accessor" do
      subject.read_groups.should == ['group-6', 'group-7']
    end
    it "should have read groups string accessor" do
      subject.read_groups_string.should == 'group-6, group-7'
    end
    it "should have read groups writer" do
      subject.read_groups = ['group-2', 'group-3']
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"discover"}
    end

    it "should have read groups string writer" do
      subject.read_groups_string = 'umg/up.dlt.staff, group-3'
      subject.rightsMetadata.groups.should == {'umg/up.dlt.staff' => 'read', 'group-3'=>'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"discover"}
    end
    it "should only revoke eligible groups" do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-7' => 'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"discover"}
    end
  end
end
