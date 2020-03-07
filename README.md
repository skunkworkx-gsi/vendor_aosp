# inital install

mkdir android

git clone https://github.com/skunkworkx-gsi/vendor_aosp.git -b android-10.0 vendor/aosp

cd vendor/aosp/treble

bash first_install.sh 

# after inital install

bash build_treble.sh
