type user =
  | Unverified
  | Verified(Save.video);

[@react.component]
let make = () => {
  let (modalVisible, setModalVisible) = React.useState(() => false);
  let (state, setState) = React.useState(() => Unverified);

  Bootstrap.(
    <>
      <Button
        onClick={() => {
          setState(_ => Unverified);
          setModalVisible(_ => true);
        }}>
        {React.string("+")}
      </Button>
      <Modal
        size="lg" show=modalVisible onHide={() => setModalVisible(_ => false)}>
        <Modal.Body>
          {switch (state) {
           | Unverified =>
             <Verify onVerified={v => setState(_ => Verified(v))} />
           | Verified(video) => <Save initial=video />
           }}
        </Modal.Body>
      </Modal>
    </>
  );
};
