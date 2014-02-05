GRAMMAR = {
  rules: {

    S: [
      [:A, :B]
      ],

    A: [
      [:A, :B, :a],
      [:B, :a, :C]
      ],

    B:  [
      [:b, :c, :C]
      ],

    C: [
      [:a, :d, :A],
      [:c]
      ]

  },

  terminals: [:a,:b,:c,:d],
  non_terminals: [:S, :A, :B, :C],
  start_symbol: :S
}
