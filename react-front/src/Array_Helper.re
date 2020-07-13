let find = (~cyclic=false, condition, array) =>
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
