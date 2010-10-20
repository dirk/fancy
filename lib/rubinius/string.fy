class String {

  # prepend a : to fancy version of ruby methods.
  ruby_alias: '==
  ruby_alias: 'upcase
  ruby_alias: 'downcase

  def [] index {
    """Given an Array of 2 Numbers, it returns the substring between the given indices.
       If given a Number, returns the character at that index."""

    # if given an Array, interpret it as a from:to: range substring
    index is_a?: Array . if_true: {
      from: (index[0]) to: (index[1])
    } else: {
      ruby: '[] args: [index] . chr
    }
  }

  def from: from to: to {
    self[~[from, to + 1]]
  }

  def each: block {
    split("") each(&block)
  }

  def at: idx {
    self[idx]
  }

  def split: str {
    split(str)
  }

  def eval {
    Fancy eval(self)
  }

  def eval_global {
    Fancy eval(self)
  }

  def to_sexp {
    "Not implemented yet!" raise!
  }

  def raise! {
    "Raises a new StdError with self as the message."
    StdError new: self . raise!
  }
}
