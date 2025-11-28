# frozen_string_literal: true

class FacialProfile < ApplicationRecord
  belongs_to :student


  validates :student_id, presence: true
  validates :embedding, presence: true

  def self.similar_to(embedding_vector, limit: 10)
    return none if embedding_vector.blank?

    vector = if embedding_vector.is_a?(Pgvector::Vector)
               embedding_vector
             else
               Pgvector::Vector.new(embedding_vector)
             end

    order(Arel.sql("embedding <-> ?"), vector.to_s)
      .limit(limit)
  end

  def self.within_distance(embedding_vector, distance: 1.0)
    return none if embedding_vector.blank?

    vector = if embedding_vector.is_a?(Pgvector::Vector)
               embedding_vector
             else
               Pgvector::Vector.new(embedding_vector)
             end

    where(Arel.sql("embedding <-> ? < ?"), vector.to_s, distance)
  end

  def distance_to(other_embedding)
    return nil if embedding.blank? || other_embedding.blank?

    other_vector = if other_embedding.is_a?(Pgvector::Vector)
                     other_embedding
                   else
                     Pgvector::Vector.new(other_embedding)
                   end

    result = self.class.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "SELECT embedding <-> ? as distance FROM facial_profiles WHERE id = ?",
        other_vector.to_s, id
      ])
    )

    result.first['distance'] if result.any?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id image_path student_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[student]
  end
end

