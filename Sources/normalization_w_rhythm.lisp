	( defun normalize
		( input )
		( map 'vector
			( lambda
				( x )
				( print
					( coerce
						( -
							( / x 64.000000 )
							1.000000 )
						'double-float )
					)
				)
			input )
		)
	( defun normalize1
		( input )
		( map 'vector
			( lambda
				( x )
				( if
					( = x 1 )
					1.0d0 -1.0d0 )
				)
			input )
		)
	( defun denormalize1
		( input )
		( map 'vector
			( lambda
				( x )
				( *
					( + x 1.000000 )
					64.000000 )
				)
			input )
		)
	( defun denormalize2
		( output )
		( map 'list
			( lambda
				( x )
				( if
					( plusp x )
					1 0 )
				)
			output )
		)
	( defvar inputs
		( mapcar #'normalize1
			( mapcar
				( function
					( lambda
						( x )
						( apply #'vector x )
						)
					)
				( quote inputsList )
				)
			)
		)
	( defvar targets
		( mapcar #'normalize1
			( mapcar
				( function
					( lambda
						( x )
						( apply #'vector x )
						)
					)
				( quote targetsList )
				)
			)
		)
	( defun convert-to-double-float-vector
		( input )
		( make-array
			( length input )
			:element-type 'double-float :initial-contents
			( map 'list
				( lambda
					( x )
					( coerce x 'double-float )
					)
				input )
			)
		)
	( defun fuzzy-equal
		( vec1 vec2 &key
			( tolerance 0.000010 )
			)
		( and
			( =
				( length vec1 )
				( length vec2 )
				)
			( loop for v1 across vec1 for v2 across vec2 always
				( <=
					( abs
						( - v1 v2 )
						)
					tolerance )
				)
			)
		)
	( defun get-prediction-and-mae
		( input nn )
		( let*
			(
				( normalized-input
					( normalize1
						( convert-to-double-float-vector input )
						)
					)
				( index
					( position normalized-input inputs :test #'fuzzy-equal )
					)
				( expected-target
					( and index
						( nth index targets )
						)
					)
				( prediction
					( snn:predict nn normalized-input )
					)
				( denormalized-prediction
					( denormalize2 prediction )
					)
				( mae
					( and expected-target
						( snn:mean-absolute-error nn
							( list normalized-input )
							( list expected-target )
							)
						)
					)
				)
			( list denormalized-prediction mae )
			)
		)
	( defun binary_to_integer_representation
		( binarylist )
		( unless
			( =
				( length binarylist )
				8 )
			( error "Input must be an 8-bit binary array" )
			)
		( let
			(
				( sign
					( if
						( =
							( first binarylist )
							1 )
						-1 1 )
					)
				( magnitude 0 )
				)
			( dotimes
				( i 7 )
				( setf magnitude
					( + magnitude
						( *
							( nth
								( 1+ i )
								binarylist )
							( expt 2
								( - 6 i )
								)
							)
						)
					)
				)
			( * sign magnitude )
			)
		)
	( defun integer_to_binary_representation
		( input )
		( let*
			(
				( abs-input
					( abs input )
					)
				( binary-list
					( make-list 8 :initial-element 0 )
					)
				)
			( dotimes
				( i
					( min 8
						( integer-length abs-input )
						)
					)
				( setf
					( nth
						( - 7 i )
						binary-list )
					( logand abs-input 1 )
					)
				( setq abs-input
					( ash abs-input -1 )
					)
				)
			( if
				( minusp input )
				( progn
					( setf
						( first binary-list )
						1 )
					)
				)
			binary-list )
		)
	( defun inputs2binary
		( inputlist )
		( patch-work::flat
			( mapcar #'integer_to_binary_representation inputlist )
			)
		)
	( defun binary2inputs
		( binarylist )
		( binary_to_integer_representation binarylist )
		)


	(defun rational-to-10bit-representation (fraction)
		(let* ((numerator (numerator fraction))
			(denominator (denominator fraction))
			(denominator-values (list 1 2 3 4 5 6 8 10 12 16 24 32))
			(denominator-index (position denominator denominator-values))
			(sign-bit (if (minusp numerator) 1 0))
			(abs-numerator (abs numerator))
			(binary-num (to-binary-list-with-padding (logand abs-numerator #x1f) 5))
			(binary-den (if denominator-index
				(to-binary-list-with-padding denominator-index 4)
				(error "Invalid denominator value")))
			(binary-representation (append (list sign-bit) binary-num binary-den)))
		binary-representation))

	(defun to-binary-list-with-padding (number target-length)
		(let ((binary-list (reverse (integer-to-binary-list number))))
			(append (make-list (- target-length (length binary-list)) :initial-element 0) binary-list)))

	(defun integer-to-binary-list (number)
		(if (= number 0)
			'(0)
			(labels ((to-list (n)
				(if (= n 0)
					'()
					(cons (mod n 2) (to-list (floor n 2))))))
			(let ((binary-list (to-list number)))
				(reverse binary-list)))))


	(defun rhythm-2-binary (rational-list)
		(mapcar #'rational-to-10bit-representation rational-list)
		)

	(defun binary-list-to-integers (binary-list)
		(let* ((sign-bit (first binary-list))
			(numerator-bits (subseq binary-list 1 6))
			(denominator-bits (subseq binary-list 6 10))
			(denominator-values (list 1 2 3 4 5 6 8 10 12 16 24 32))
			(numerator (bit-list-to-integer numerator-bits))
			(denominator-index (bit-list-to-integer denominator-bits))
			(denominator (nth denominator-index denominator-values))
			(full-numerator (if (= sign-bit 1) (- numerator) numerator)))
		(list full-numerator denominator)))

	(defun bit-list-to-integer (bit-list)
		(reduce (lambda (acc bit) (+ (* acc 2) bit)) bit-list :initial-value 0))

	(defun integers-to-rational (integers)
		(let ((numerator (first integers))
			(denominator (second integers)))
		(if (/= denominator 0)
			(/ numerator denominator)
			(error "Denominator cannot be zero."))))

	(defun binary-list-to-rational (binary-list)
		(let ((fraction-pair (binary-list-to-integers binary-list)))
			(integers-to-rational fraction-pair)))

	(defun binary-2-rhythm (binary-list)
		(mapcar #'binary-list-to-rational binary-list))

