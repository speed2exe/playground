use std::borrow::Borrow;

fn main() {
    let my_struct = MyStruct {
        id: 1,
        name: "ho".to_string(),
    };

    println!("my_struct: {:?}", my_struct);
    some_func(&my_struct);
    some_func_2(my_struct);
}

fn some_func(s: &MyStruct) {
    println!("s: {:?}", s);
}

fn some_func_2<B>(s: B)
where
    B: Borrow<MyStruct> + std::fmt::Debug,
{
    println!("s: {:?}", s);
}

#[derive(Debug)]
#[allow(dead_code)]
struct MyStruct {
    id: i32,
    name: String,
}
