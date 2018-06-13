import unit_threaded;

int main(string[] args) {
    return args.runTests!(
        "ut.exclusive",
    );
}
