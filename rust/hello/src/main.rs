use std::borrow::{Borrow, BorrowMut};

fn main() {
    let mut my_struct = MyStruct {
        id: 1,
        name: "ho".to_string(),
    };

    println!("my_struct: {:?}", my_struct);
    func1(&my_struct);
    func2(my_struct.borrow());
    func2(my_struct.borrow());
    let c = my_struct.borrow_mut();
    let d = my_struct.borrow();
    func2(my_struct.borrow());
    func2(my_struct.borrow());
}

fn func1(s: &MyStruct) {
    println!("s: {:?}", s);
}

fn func2<B>(s: B)
where
    B: Borrow<MyStruct> + std::fmt::Debug,
{
    println!("s: {:?}", s);
}

fn func3<B>(s: B)
where
    B: BorrowMut<MyStruct> + std::fmt::Debug,
{
    println!("s: {:?}", s);
}

#[derive(Debug)]
#[allow(dead_code)]
struct MyStruct {
    id: i32,
    name: String,
}
