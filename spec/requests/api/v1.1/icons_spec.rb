describe "v1.1 - IconsRequests", :type => [:request, :v1x1] do
  let!(:portfolio_item) { create(:portfolio_item) }
  let!(:portfolio) { create(:portfolio) }

  let!(:icon) do
    create(:icon, :image => image, :restore_to => portfolio_item).tap do |icon|
      icon.restore_to.update!(:icon_id => icon.id)
    end
  end
  let!(:portfolio_icon) do
    create(:icon, :image => image, :restore_to => portfolio).tap do |icon|
      icon.restore_to.update!(:icon_id => icon.id)
    end
  end

  let(:image) { create(:image) }

  describe "#destroy" do
    before { delete "#{api_version}/icons/#{icon.id}", :headers => default_headers }

    it "returns a 204" do
      expect(response).to have_http_status(:no_content)
    end

    it "deletes the icon" do
      expect { Icon.find(icon.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "removes the reference on the restore_to object" do
      icon.reload
      expect(icon.restore_to.icon_id).to be_falsey
    end
  end

  describe "#create" do
    let!(:ocp_jpg_image) do
      create(:image,
             :content   => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.jpg"))),
             :extension => "JPEG")
    end
    let!(:ocp_png_image) do
      create(:image,
             :content   => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.png"))),
             :extension => "PNG")
    end
    let(:max_image_size) { Image::MAX_IMAGE_SIZE }

    before do
      stub_const("Image::MAX_IMAGE_SIZE", max_image_size)

      post "#{api_version}/icons", :params => params, :headers => default_headers, :as => :form
    end

    context "when providing proper parameters" do
      let(:params) { {:content => form_upload_test_image("ocp_logo.svg"), :portfolio_item_id => portfolio_item.id} }

      it "returns a 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the created icon" do
        expect(json["image_id"]).to be_truthy
      end
    end

    context "when uploading a duplicate svg icon" do
      let(:params) { {:content => form_upload_test_image("ocp_logo.svg"), :portfolio_item_id => portfolio_item.id} }

      it "uses the reference from the one that is already there" do
        expect(json["image_id"]).to eq image.id.to_s
      end
    end

    context "when uploading a duplicate png icon" do
      let(:params) do
        {
          :content           => form_upload_test_image("ocp_logo_dupe.png"),
          :portfolio_item_id => portfolio_item.id
        }
      end

      it "uses the already-existing image" do
        expect(json["image_id"]).to eq ocp_png_image.id.to_s
      end
    end

    context "when uploading a duplicate jpg icon" do
      let(:params) do
        {
          :content           => form_upload_test_image("ocp_logo_dupe.jpg"),
          :portfolio_item_id => portfolio_item.id
        }
      end

      it "uses the already-existing image" do
        expect(json["image_id"]).to eq ocp_jpg_image.id.to_s
      end
    end

    context "when passing in improper parameters" do
      let(:params) { { :not_the_right_param => "whereami" } }

      it "throws a 400" do
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when not passing in a portfolio or portfolio_item id" do
      let(:params) do
        {:content => form_upload_test_image("miq_logo.png")}
      end

      it "throws a 400" do
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when uploading a png" do
      let(:params) do
        {:content           => form_upload_test_image("miq_logo.png"),
         :portfolio_item_id => portfolio_item.id}
      end

      it "makes a new image and icon" do
        expect(response).to have_http_status 200
        expect(json["image_id"]).to_not eq image.id
      end
    end

    context "when uploading a jpg" do
      let(:params) do
        {:content           => form_upload_test_image("miq_logo.jpg"),
         :portfolio_item_id => portfolio_item.id}
      end

      it "makes a new image and icon" do
        expect(response).to have_http_status 200
        expect(json["image_id"]).to_not eq image.id
      end
    end

    context "when uploading an image that is too large" do
      let(:params) do
        {:content           => form_upload_test_image("miq_logo.jpg"),
         :portfolio_item_id => portfolio_item.id}
      end
      let(:max_image_size) { 1.kilobyte }

      it "returns bad request" do
        expect(response).to have_http_status(:bad_request)
      end

      it "throws ActiveRecord::RecordInvalid" do
        expect(first_error_detail).to match(/ActiveRecord::RecordInvalid/)
      end
    end
  end

  describe "#raw_icon" do
    context "when the icon exists" do
      it "/portfolio_items/{portfolio_item_id}/icon returns the icon" do
        get "#{api_version}/portfolio_items/#{portfolio_item.id}/icon", :headers => default_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq "image/svg+xml"
      end

      it "/portfolios/{portfolio_id}/icon returns the icon" do
        get "#{api_version}/portfolios/#{portfolio.id}/icon", :headers => default_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq "image/svg+xml"
      end
    end

    context "when the icon does not exist" do
      before do
        portfolio_item.icon.discard
        portfolio.icon.discard
      end

      it "/portfolio_items/{id}/icon returns no content" do
        get "#{api_version}/portfolio_items/#{portfolio_item.id}/icon", :headers => default_headers

        expect(response).to have_http_status(:no_content)
      end

      it "/portfolios/{id}/icon returns no content" do
        get "#{api_version}/portfolios/#{portfolio.id}/icon", :headers => default_headers

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
