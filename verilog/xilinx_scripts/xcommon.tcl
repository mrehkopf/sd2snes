proc existsProp { props name } {
    if { [lsearch $props $name] >= 0 } {
        return 1
    } else {
        return 0
    }
}

proc getpartname {} {
  return [project get Device][project get "Speed Grade"][project get Package]
}
