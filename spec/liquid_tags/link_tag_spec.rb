require "rails_helper"

RSpec.describe LinkTag, type: :liquid_template do
  let(:user) { create(:user, username: "username45", name: "Chase Danger", profile_image: nil) }
  let(:article) do
    create(:article, user_id: user.id, title: "test this please", tags: "tag1 tag2 tag3")
  end
  let(:org) { create(:organization) }
  let(:org_user) { create(:user, organization_id: org.id) }
  let(:org_article) do
    create(:article, user_id: org_user.id, title: "test this please", tags: "tag1 tag2 tag3",
                     organization_id: org.id)
  end

  def generate_new_liquid(slug)
    Liquid::Template.register_tag("link", LinkTag)
    Liquid::Template.parse("{% link #{slug} %}")
  end

  def correct_link_html(article)
    tags = article.tag_list.map { |t| "<span class='ltag__link__tag'>##{t}</span>" }.reverse.join
    <<~HTML
      <div class='ltag__link'>
        <a href='#{article.user.path}' class='ltag__link__link'>
          <div class='ltag__link__pic'>
            <img src='#{ProfileImage.new(article.user).get(150)}' alt='#{article.user.username} image'/>
          </div>
        </a>
        <a href='#{article.path}' class='ltag__link__link'>
          <div class='ltag__link__content'>
            <h2>#{ActionController::Base.helpers.strip_tags(article.title)}</h2>
            <h3>#{article.user.name} ・ #{article.readable_publish_date} ・ #{article.reading_time} min read</h3>
            <div class='ltag__link__taglist'>
              #{tags}
            </div>
          </div>
        </a>
      </div>
    HTML
  end

  it "raises an error when invalid" do
    expect { generate_new_liquid("fake_username/fake_article_slug") }.
      to raise_error("Invalid link URL or link URL does not exist")
  end

  it "renders a proper link tag" do
    liquid = generate_new_liquid("#{user.username}/#{article.slug}")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "also tries to look for article by organization if failed to find by username" do
    liquid = generate_new_liquid("#{org_article.username}/#{org_article.slug}")
    expect(liquid.render).to eq(correct_link_html(org_article))
  end

  it "renders with a leading slash" do
    liquid = generate_new_liquid("/#{user.username}/#{article.slug}")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "renders with a trailing slash" do
    liquid = generate_new_liquid("#{user.username}/#{article.slug}/")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "renders with both leading and trailing slashes" do
    liquid = generate_new_liquid("/#{user.username}/#{article.slug}/")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "renders with a full link" do
    liquid = generate_new_liquid("https://dev.to/#{user.username}/#{article.slug}")
    expect(liquid.render).to eq(correct_link_html(article))
  end

  it "renders default reading time of 1 minute for short articles" do
    liquid = generate_new_liquid("/#{user.username}/#{article.slug}/")
    expect(liquid.render).to include('1 min read')
  end

  it "renders reading time of article lengthy articles" do
    template = file_fixture("article_long_content.txt").read
    article = create(:article, user: user, body_markdown: template)
    liquid = generate_new_liquid("/#{user.username}/#{article.slug}/")
    expect(liquid.render).to include('3 min read')
  end

  it "renders with a full link with a trailing slash" do
    liquid = generate_new_liquid("https://dev.to/#{user.username}/#{article.slug}/")
    expect(liquid.render).to eq(correct_link_html(article))
  end
end
