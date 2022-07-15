entries?.filterNotNull()?.map { it.filterNotNull().fold(1) { x, y -> x * y } }?.sortedBy { abs(it) }
