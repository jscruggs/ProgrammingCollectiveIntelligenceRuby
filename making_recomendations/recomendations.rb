include Math
# A hash of movie critics and their ratings of a small set of movies 
CRITICS={'Lisa Rose'=> {'Lady in the Water'=> 2.5, 'Snakes on a Plane'=> 3.5, 
                        'Just My Luck'=> 3.0, 'Superman Returns'=> 3.5, 'You, Me and Dupree'=> 2.5, 
                        'The Night Listener'=> 3.0}, 
        'Gene Seymour'=> {'Lady in the Water'=> 3.0, 'Snakes on a Plane'=> 3.5, 
                        'Just My Luck'=> 1.5, 'Superman Returns'=> 5.0, 'The Night Listener'=> 3.0, 
                        'You, Me and Dupree'=> 3.5}, 
        'Michael Phillips'=> {'Lady in the Water'=> 2.5, 'Snakes on a Plane'=> 3.0, 
                        'Superman Returns'=> 3.5, 'The Night Listener'=> 4.0}, 
        'Claudia Puig'=> {'Snakes on a Plane'=> 3.5, 'Just My Luck'=> 3.0, 
                        'The Night Listener'=> 4.5, 'Superman Returns'=> 4.0, 
                        'You, Me and Dupree'=> 2.5}, 
        'Mick LaSalle'=> {'Lady in the Water'=> 3.0, 'Snakes on a Plane'=> 4.0, 
                        'Just My Luck'=> 2.0, 'Superman Returns'=> 3.0, 'The Night Listener'=> 3.0, 
                        'You, Me and Dupree'=> 2.0}, 
        'Jack Matthews'=> {'Lady in the Water'=> 3.0, 'Snakes on a Plane'=> 4.0, 
                        'The Night Listener'=> 3.0, 'Superman Returns'=> 5.0, 'You, Me and Dupree'=> 3.5}, 
        'Toby'=> {'Snakes on a Plane'=>4.5,'You, Me and Dupree'=>1.0,'Superman Returns'=>4.0}}

# Returns a distance-based similarity score for person1 and person2 
def sim_distance(preferences, person1, person2)
  have_movies_in_common = preferences[person1].detect {|movie, rating| preferences[person2].keys.include?(movie) }
  
  # if they have no ratings in common, return 0 
  return 0 unless have_movies_in_common
  
  # Add up the squares of all the differences 
  sum_of_squares = 0
  preferences[person1].each do |movie, rating| 
    sum_of_squares += (rating - preferences[person2][movie])**2 if preferences[person2].keys.include?(movie) 
  end

  return 1/(1 + sum_of_squares)
end


# Returns the Pearson correlation coefficient for p1 and p2 
def sim_pearson(preferences, p1, p2)
  # Get the list of shared_items 
  shared_items=[] 
  preferences[p1].each do |movie, rating| 
    shared_items << movie if preferences[p2].keys.include?(movie) 
  end
  
  # if they have no ratings in common, return 0 
  return 0 if shared_items.size == 0
  
  # Add up all the preferences 
  sum1 = shared_items.inject(0) { |sum, movie| sum + preferences[p1][movie] }
  sum2 = shared_items.inject(0) { |sum, movie| sum + preferences[p2][movie] }
  
  # Sum up the squares 
  sum1Sq = shared_items.inject(0) { |sum, movie| sum + preferences[p1][movie]**2 }
  sum2Sq = shared_items.inject(0) { |sum, movie| sum + preferences[p2][movie]**2 }
 
  # Sum up the products 
  pSum = shared_items.inject(0) { |sum, movie| sum + preferences[p1][movie] * preferences[p2][movie] }

  # Calculate Pearson score 
  num = pSum-(sum1*sum2/shared_items.size) 
  den = sqrt((sum1Sq - sum1**2 / shared_items.size)*(sum2Sq - sum2**2 / shared_items.size)) 
  return 0 if den == 0
  r = num/den 
  return r
end

# Flips preferences around so that it is organized by movie EX:
# {'Lady in the Water' => {'Lisa Rose':2.5,'Gene Seymour':3.0}, 'Snakes on a Plane'=>{'Lisa Rose':3.5,'Gene Seymour':3.5}} etc  
def transform_preferences(preferences)
  result={} 
  preferences.keys.each do |person|
    preferences[person].each do |movie_and_rating|
      result[movie_and_rating[0]] ||= {}
      result[movie_and_rating[0]][person] = movie_and_rating[1]
    end
  end
  
  return result
end

# Returns the best matches for person from the preferences dictionary. 
def top_matches(preferences, person, limit = 5)
  scores = preferences.map {|pref| [sim_pearson(preferences, person, pref[0]), pref[0]] unless pref[0] == person}.compact
  scores.sort! {|a,b| b[0] <=> a[0]}
  return scores[0...limit]
end

# Create a dictionary of items showing which other items they 
# are most similar to.
def calculate_similar_items(preferences, limit = 10)
  result = {} 
  # Invert the preference matrix to be item-centric 
  item_preferences = transform_preferences(preferences) 
  item_preferences.keys.each do |item|
    # Find the most similar items to this one 
    scores = top_matches(item_preferences, item, limit) 
    result[item] = scores
  end
  return result
end

def get_recommended_items(preferences, similarities_of_items, user)
  user_ratings = preferences[user]
  sums_of_weighted_simularities = {}
  sums_of_simularities = {}
  # Loop over items rated by this user 
  user_ratings.each do |item,rating| 
    # Loop over items similar to this one
    similarities_of_items[item].each do |similarity,item2| 
      # Ignore if this user has already rated this item 
      next if user_ratings.include?(item2)
      # Weighted sum of rating times similarity 
      sums_of_weighted_simularities[item2] ||= 0 
      sums_of_weighted_simularities[item2] += similarity * rating 
      # Sum of all the similarities 
      sums_of_simularities[item2] ||= 0 
      sums_of_simularities[item2] += similarity 
    end
  end
  # Divide each total score by total weighting to get an average
  rankings = sums_of_weighted_simularities.map {|movie, sim_score| [sim_score/sums_of_simularities[movie], movie]}
  # Return the rankings from highest to lowest 
  rankings.sort {|a,b| b[0] <=> a[0]} 
end
