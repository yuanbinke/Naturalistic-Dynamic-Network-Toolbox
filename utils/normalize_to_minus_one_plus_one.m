function normalized_matrix = normalize_to_minus_one_plus_one(matrix)
    min_val = min(matrix(:));
    max_val = max(matrix(:));
    
    matrix_normalized_01 = (matrix - min_val) / (max_val - min_val);
    
    normalized_matrix = 2 * matrix_normalized_01 - 1;
end