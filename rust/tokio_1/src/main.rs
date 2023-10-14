#[tokio::main]
async fn main() {
    let handle = tokio::spawn(async move {
        println!("----- inserting updates");
        // The rest of your async block here
    });
    std::thread::sleep(std::time::Duration::from_secs(2));
}
