require 'datamapper'
require 'erb'
require 'ostruct'

class Resource
  include DataMapper::Resource

  property :id, Serial
  property :mime, String
  property :article_id, Integer
end

class Content
  include DataMapper::Resource

  property :article_id, Integer
  property :author, String
  property :body, Text
  property :extended, Text
  property :created_at, Date
  property :id, Serial
  property :title, String
  property :permalink, String

  def full_body
    body << extended
  end

  def clean_body
    full_body.gsub('<typo:code linenumber="true" class="code-example">', '{% highlight actionscript %}').
      gsub('</typo:code>', "{% endhighlight %}")
  end

  def author_label
    return "Luke Bayes" if author == "lbayes"
    return "Ali Mills" if author == "amills"
    return author
  end

  def file_name
    "#{created_at.to_s}-#{permalink}.textile"
  end

  def safe_title
    title.gsub('::', '-').
      gsub(':', '').
      gsub('(', '').
      gsub(')', '')
  end

  def clean_title
    safe_title.strip.downcase.gsub(' ', '-').
      gsub('/', '-').
      gsub('.', '-').
      gsub('=', '').
      gsub('[', '').
      gsub(']', '').
      gsub(':', '').
      gsub('\'', '').
      gsub('\/', '').
      gsub(',','').
      gsub('(', '').
      gsub(')', '').
      gsub('!','').
      gsub('?', '').
      gsub('--', '-').
      gsub('--', '-')
  end

  def get_binding
    binding
  end
end

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup :default, 'mysql://localhost/asserttrue_2008'

def render_post template, post
  #puts ">> rendering: #{post.file_name}"
  source = ERB.new template
  source.result(post.get_binding)
end

def should_publish? post
  post.title.match(/Invest Regulary in Your Knowledge Portfolio/).nil? &&
    post.title.match(/San Francisco Design Patterns Study Group meeting tonight/).nil?

end

template = File.read 'date-title.textile'

posts = Content.all(:conditions => { :title.not => nil, :author.not => nil})
posts.each do |post|
  #puts ">> Post: #{post.file_name}"
  if should_publish?(post)
    File.open("../_posts/#{post.file_name}", 'w+') do |f|
      content = render_post(template, post)
      puts ">> Content: #{content}"
      f.write content
    end
  end
end

puts "======================="
puts "Processed #{posts.size} Posts"
