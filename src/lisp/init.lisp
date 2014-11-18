(cl:in-package :cl-user)
#-asdf
(require :asdf)

(defpackage :ros
  (:use :cl)
  (:shadow :load :eval :package :restart :print :write))

(in-package :ros)
(push :ros.init *features*)
(defvar *verbose* 0)
(export (defvar *argv* nil))

(defun source-registry (cmd arg &rest rest)
  (declare (ignorable cmd rest))
  (asdf:initialize-source-registry arg))

(defun system (cmd arg &rest rest)
  (declare (ignorable cmd rest))
  #-quicklisp(asdf:operate 'asdf:load-op arg)
  #+quicklisp(ql:quickload arg))

(setf (fdefinition 'load-systm)
      #'system)

(defun package (cmd arg &rest rest)
  (declare (ignorable cmd rest))
  (setq *package* (find-package (read-from-string (format nil "#:~A" arg)))))

(defun system-package (cmd arg &rest rest)
  (declare (ignorable cmd rest))
  (apply #'system cmd arg rest)
  (apply #'package cmd arg rest))

(defun eval (cmd arg &rest rest)
  (declare (ignorable cmd rest))
  (cl:eval (read-from-string arg)))

(defun quit (cmd &rest rest)
  (declare (ignorable cmd rest))
  #+sbcl
  (sb-ext:exit))

(defun restart (cmd arg &rest rest)
  (declare (ignorable cmd rest))
  (funcall (read-from-string arg)))

(defun entry (cmd arg &rest rest)
  (declare (ignorable cmd rest))
  (apply (read-from-string arg) *argv*))

(setf (fdefinition 'init) #'eval)

(defun print (cmd arg &rest rest)
  (declare (ignorable cmd rest))
  (cl:print (cl:eval (read-from-string arg))))

(defun write (cmd arg &rest rest)
  (declare (ignorable cmd rest))
  (cl:write (cl:eval (read-from-string arg))))

(export
 (defun script (cmd arg &rest rest)
   (declare (ignorable cmd arg))
   (setf *argv* rest)
   (with-open-file (in arg)
     (let ((line(read-line in)))
       (cl:load (make-concatenated-stream
                 (make-string-input-stream
                  (format nil "(cl:setf cl:*load-pathname* #P~S)(cl:setf cl:*load-truename* (truename cl:*load-pathname*))~A" arg
                          (if (equal (subseq line 0 (min (length line) 2)) "#!")
                              "" line)))
                 in
                 (make-string-input-stream
                  (if (eql cmd :script)
                      "(cl:apply 'main ros:*argv*)"
                      ""))))))))

(defun load (x file)
  (declare (ignore x))
  (cl:load file))

(export 
 (defun run (list)
   (loop :for elt :in list
      :do (apply (intern (string (first elt)) (find-package :ros)) elt))))
