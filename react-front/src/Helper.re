module Array = {
  let next = (~cyclic=false, condition, array) =>
    array
    ->Belt_Array.getIndexBy(condition)
    ->Belt_Option.flatMap(i => {
        let index =
          if (cyclic) {
            (i + 1) mod Belt_Array.length(array);
          } else {
            i + 1;
          };
        Belt_Array.get(array, index);
      });
};
module Time = {
  let formatSeconds = t =>
    [t / 3600, t / 60 mod 60, t mod 60]
    |> List.map(t =>
         [t / 10, t mod 10] |> List.map(string_of_int) |> String.concat("")
       )
    |> String.concat(":");
};
