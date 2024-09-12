#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int main() {
    vector<int> v;
    int i;
    while (cin >> i) v.push_back(i);

    std::sort(v.begin(), v.end());


    for (auto& i : v) {
        cout << i << " ";
    }
    cout << endl;

    return 0;
}
