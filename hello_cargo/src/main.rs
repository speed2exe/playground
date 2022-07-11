fn main() {
    let a = [1, 2, 3];
    // print type of a
    println!("value: {:?}", a);
    print_type_of(&a);

    let mut b: [i32; 5] = unsafe { std::mem::uninitialized() };
    // initialize b
    // b.write([1, 2, 3]);

    // print type of a
    println!("value: {:?}", b);
    print_type_of(&b);
}

// print typeof
fn print_type_of<T>(_: &T) {
    println!("type: {}", std::any::type_name::<T>());
}
a
