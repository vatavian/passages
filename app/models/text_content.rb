class TextContent < ApplicationRecord
  has_many :passages, as: :body
end