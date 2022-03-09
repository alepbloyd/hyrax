# frozen_string_literal: true

RSpec.describe Hyrax::Forms::PcdmCollectionForm do
  subject(:form)   { described_class.new(collection) }
  let(:collection) { Hyrax::PcdmCollection.new }

  describe '.required_fields' do
    it 'lists required fields' do
      expect(described_class.required_fields)
        .to contain_exactly(:title, :collection_type_gid, :depositor)
    end
  end

  describe '#primary_terms' do
    it 'gives "title" as a primary term' do
      expect(form.primary_terms).to contain_exactly(:title, :description)
    end
  end

  describe '.validate' do
    let(:collection_type_gid) { FactoryBot.create(:user_collection_type).to_global_id.to_s }

    context 'when all required fields are present' do
      let(:valid_params) do
        { title: 'My title', collection_type_gid: collection_type_gid }
      end
      it 'returns true' do
        expect(form.validate(valid_params)).to eq true
      end
    end

    context 'when title is missing' do
      let(:params_missing_title) do
        { collection_type_gid: collection_type_gid }
      end
      it 'returns error messages for missing field' do
        expect(form.validate(params_missing_title)).to eq false
        expect(form.errors.messages).to include(title: ["can't be blank"])
        expect(form.errors.messages).not_to include(collection_type_gid: ["can't be blank"])
      end
    end

    context 'when collection_type_gid is missing' do
      let(:params_missing_type) do
        { title: 'My title' }
      end
      it 'returns error message for field' do
        expect(form.validate(params_missing_type)).to eq false
        expect(form.errors.messages).to include(collection_type_gid: ["can't be blank"])
        expect(form.errors.messages).not_to include(title: ["can't be blank"])
      end
    end

    context 'when all required fields are missing' do
      let(:params_missing_all_required) do
        { description: 'A description of the collection.' }
      end
      it 'returns error messages for all missing required fields' do
        expect(form.validate(params_missing_all_required)).to eq false
        expect(form.errors.messages).to include(title: ["can't be blank"])
        expect(form.errors.messages).to include(collection_type_gid: ["can't be blank"])
      end
    end
  end
end
