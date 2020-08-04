class StoryFormat < ApplicationRecord

  def self.for(name, version)
    find_by(name: name, version: version) || find_by(name: name) || first
  end

end
